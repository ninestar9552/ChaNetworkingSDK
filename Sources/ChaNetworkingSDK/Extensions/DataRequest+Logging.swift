//
//  DataRequest+Logging.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/10/25.
//

import Foundation
import Alamofire

internal struct MultipartLogPayload: Sendable {
    let fields: [MultipartField]
    let files: [MultipartFile]
}

extension DataRequest {
    internal func log(
        dataResponse: DataResponse<Data, AFError>,
        logging: Bool,
        multipartPayload: MultipartLogPayload? = nil
    ) {
        guard logging else { return }
        print(logDescription(dataResponse, multipartPayload: multipartPayload))
    }

    private func logDescription(
        _ dataResponse: DataResponse<Data, AFError>,
        multipartPayload: MultipartLogPayload?
    ) -> String {
        var lines = ["===== NETWORK ====="]

        appendRequest(dataResponse.request, multipartPayload: multipartPayload, to: &lines)

        lines.append("")
        lines.append("[cURL]")
        lines.append(indent(self.cURLDescription()))

        lines.append("")
        appendResponse(dataResponse, to: &lines)

        lines.append("")
        lines.append("[Result]")
        appendResult(dataResponse, to: &lines)
        lines.append("===================")

        return lines.joined(separator: "\n")
    }

    private func appendRequest(
        _ request: URLRequest?,
        multipartPayload: MultipartLogPayload?,
        to lines: inout [String]
    ) {
        lines.append("[Request]")
        guard let request else {
            lines.append("No URLRequest")
            return
        }

        lines.append("\(request.httpMethod ?? "UNKNOWN") \(request.url?.absoluteString ?? "")")
        append(headers: request.allHTTPHeaderFields, title: "Headers", to: &lines)

        if let body = bodyString(request.httpBody) {
            lines.append("Body:")
            lines.append(indent(body))
        } else if let multipartPayload {
            lines.append("Body: multipart/form-data (streamed body; raw body unavailable)")
            appendMultipartPayload(multipartPayload, to: &lines)
        } else {
            lines.append("Body: None")
        }
    }

    private func appendResponse(_ dataResponse: DataResponse<Data, AFError>, to lines: inout [String]) {
        lines.append("[Response]")
        let requestLine = requestLine(from: dataResponse.request)
        if let response = dataResponse.response {
            lines.append(requestLine)
            lines.append("Status Code: \(response.statusCode)")
            appendTiming(dataResponse, to: &lines)
            append(headers: response.allHeaderFields, title: "Headers", to: &lines)
        } else {
            lines.append(requestLine)
            lines.append("Status Code: No HTTP response")
            appendTiming(dataResponse, to: &lines)
        }

        if let body = bodyString(dataResponse.data) {
            lines.append("Body:")
            lines.append(indent(body))
        } else {
            lines.append("Body: None")
        }
    }

    private func requestLine(from request: URLRequest?) -> String {
        guard let request else {
            return "UNKNOWN"
        }
        return "\(request.httpMethod ?? "UNKNOWN") \(request.url?.absoluteString ?? "")"
    }

    private func append(headers: [AnyHashable: Any]?, title: String, to lines: inout [String]) {
        let normalizedHeaders = headers?.compactMap { key, value -> (String, String)? in
            guard let key = key as? String else { return nil }
            return (key, "\(value)")
        } ?? []

        append(headers: normalizedHeaders, title: title, to: &lines)
    }

    private func append(headers: [String: String]?, title: String, to lines: inout [String]) {
        let normalizedHeaders = headers?.map { ($0.key, $0.value) } ?? []
        append(headers: normalizedHeaders, title: title, to: &lines)
    }

    private func append(headers: [(String, String)], title: String, to lines: inout [String]) {
        guard !headers.isEmpty else {
            lines.append("\(title): None")
            return
        }

        lines.append("\(title):")
        headers.sorted { $0.0 < $1.0 }.forEach { key, value in
            lines.append("  \(key): \(value)")
        }
    }

    private func appendTiming(_ dataResponse: DataResponse<Data, AFError>, to lines: inout [String]) {
        if let duration = dataResponse.metrics?.taskInterval.duration {
            lines.append("Network Duration: \(duration)s")
        }
        lines.append("Serialization Duration: \(dataResponse.serializationDuration)s")
    }

    private func bodyString(_ data: Data?) -> String? {
        guard let data, !data.isEmpty else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func appendMultipartPayload(_ payload: MultipartLogPayload, to lines: inout [String]) {
        lines.append("Multipart:")
        lines.append("  Fields (\(payload.fields.count), \(payload.fields.reduce(0) { $0 + $1.data.count }) bytes):")
        if payload.fields.isEmpty {
            lines.append("    None")
        } else {
            payload.fields.forEach { field in
                var line = "    - \(field.name): \(field.data.count) bytes"
                if let mimeType = field.mimeType {
                    line += ", mimeType=\(mimeType)"
                }
                lines.append(line)

                if let preview = fieldPreview(field.data) {
                    lines.append("      preview: \(preview)")
                }
            }
        }

        lines.append("  Files (\(payload.files.count), \(payload.files.reduce(0) { $0 + $1.data.count }) bytes):")
        if payload.files.isEmpty {
            lines.append("    None")
        } else {
            payload.files.forEach { file in
                lines.append(
                    "    - \(file.name): fileName=\(file.fileName), mimeType=\(file.mimeType), size=\(file.data.count) bytes"
                )
            }
        }
    }

    private func fieldPreview(_ data: Data, limit: Int = 512) -> String? {
        guard let string = String(data: data, encoding: .utf8),
              string.isEmpty == false else {
            return nil
        }

        let singleLine = string
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\n", with: "\\n")

        guard singleLine.count > limit else {
            return singleLine
        }
        return "\(singleLine.prefix(limit))... <truncated>"
    }

    private func indent(_ text: String) -> String {
        text.split(separator: "\n", omittingEmptySubsequences: false)
            .map { "  \($0)" }
            .joined(separator: "\n")
    }

    private func appendResult(_ dataResponse: DataResponse<Data, AFError>, to lines: inout [String]) {
        switch dataResponse.result {
        case .success(let data):
            lines.append("success (\(data.count) bytes)")
        case .failure(let error):
            lines.append("failure")
            appendHTTPStatus(dataResponse.response, to: &lines)
            appendServerErrorSummary(dataResponse.data, to: &lines)
            lines.append("Error Type: \(errorTypeName(error))")
            lines.append("Error Description: \(error.localizedDescription)")
            lines.append("Error Detail:")
            lines.append(indent(String(describing: error)))
        }
    }

    private func appendHTTPStatus(_ response: HTTPURLResponse?, to lines: inout [String]) {
        if let response {
            lines.append("HTTP: \(response.statusCode)")
        }
    }

    private func appendServerErrorSummary(_ data: Data?, to lines: inout [String]) {
        guard let summary = errorSummary(from: data) else { return }
        lines.append("Server Error: \(summary)")
    }

    private func errorTypeName(_ error: Error) -> String {
        String(reflecting: type(of: error))
    }

    private func errorSummary(from data: Data?) -> String? {
        guard let data, !data.isEmpty,
              let object = try? JSONSerialization.jsonObject(with: data),
              let dictionary = object as? [String: Any] else {
            return nil
        }

        let code = firstStringValue(in: dictionary, keys: ["errorCode", "code", "status"])
        let message = firstStringValue(in: dictionary, keys: ["errorMsg", "message", "error"])

        switch (code, message) {
        case let (code?, message?):
            return "\(code) \(message)"
        case let (code?, nil):
            return code
        case let (nil, message?):
            return message
        case (nil, nil):
            return nil
        }
    }

    private func firstStringValue(in dictionary: [String: Any], keys: [String]) -> String? {
        for key in keys {
            guard let value = dictionary[key] else { continue }
            let stringValue = "\(value)"
            if !stringValue.isEmpty {
                return stringValue
            }
        }
        return nil
    }
}

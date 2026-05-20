//
//  MultipartPayload.swift
//  ChaNetworkingSDK
//
//  Created by OpenAI on 5/14/26.
//

import Foundation

/// multipart/form-data 일반 필드입니다.
public struct MultipartField: Sendable {
    public let name: String
    public let data: Data
    public let mimeType: String?

    public init(name: String, value: String, encoding: String.Encoding = .utf8) {
        self.name = name
        self.data = value.data(using: encoding) ?? Data()
        self.mimeType = nil
    }

    public init(name: String, data: Data, mimeType: String? = nil) {
        self.name = name
        self.data = data
        self.mimeType = mimeType
    }

    public init<Value: Encodable>(
        name: String,
        json value: Value,
        encoder: JSONEncoder = JSONEncoder(),
        mimeType: String? = nil
    ) throws {
        self.name = name
        self.data = try encoder.encode(value)
        self.mimeType = mimeType
    }
}

/// multipart/form-data 파일 필드입니다.
public struct MultipartFile: Sendable {
    public let name: String
    public let data: Data
    public let fileName: String
    public let mimeType: String

    public init(name: String, data: Data, fileName: String, mimeType: String) {
        self.name = name
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
    }
}

//
//  MultipartPayloadTests.swift
//  ChaNetworkingSDK
//
//  Created by OpenAI on 5/20/26.
//

import Foundation
import Testing
@testable import ChaNetworkingSDK

final class MultipartPayloadTests {
    private struct MockJSONField: Encodable {
        let petSeq: Int
        let petName: String
    }

    @Test func testStringField() throws {
        let field = MultipartField(name: "description", value: "profile image")

        #expect(field.name == "description")
        #expect(String(data: field.data, encoding: .utf8) == "profile image")
        #expect(field.mimeType == nil)
    }

    @Test func testJSONField() throws {
        let field = try MultipartField(
            name: "jsonData",
            json: MockJSONField(petSeq: 1, petName: "Buddy")
        )

        let json = try JSONSerialization.jsonObject(with: field.data) as? [String: Any]

        #expect(field.name == "jsonData")
        #expect(json?["petSeq"] as? Int == 1)
        #expect(json?["petName"] as? String == "Buddy")
        #expect(field.mimeType == nil)
    }

    @Test func testJSONFieldWithMimeType() throws {
        let field = try MultipartField(
            name: "jsonData",
            json: MockJSONField(petSeq: 1, petName: "Buddy"),
            mimeType: "application/json"
        )

        #expect(field.mimeType == "application/json")
    }
}

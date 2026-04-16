import Testing
import Foundation
@testable import RequestResponse

private struct DecodeModel: Codable, Sendable, Equatable {
    let name: String
}

@Test func bodyCodec_encodeData_passthrough() async throws {
    let input = Data([1, 2, 3])
    let output = try await encodeBody(input, using: JSONEncoder())

    #expect(output == input)
}

@Test func bodyCodec_encodeString_utf8() async throws {
    let output = try await encodeBody("hello", using: JSONEncoder())
    #expect(output == Data("hello".utf8))
}

@Test func bodyCodec_decodeData_passthrough() async throws {
    let input = Data([9, 8, 7])
    let output: Data = try await decodeBody(input, using: JSONDecoder())

    #expect(output == input)
}

@Test func bodyCodec_decodeString_utf8() async throws {
    let output: String = try await decodeBody(Data("hello".utf8), using: JSONDecoder())
    #expect(output == "hello")
}

@Test func bodyCodec_decodeEmptyToOptionalNil() async throws {
    let output: String? = try await decodeBody(Data(), using: JSONDecoder())
    #expect(output == nil)
}

@Test func bodyCodec_decodeJSONModel() async throws {
    let input = Data(#"{"name":"alex"}"#.utf8)
    let output: DecodeModel = try await decodeBody(input, using: JSONDecoder())

    #expect(output == DecodeModel(name: "alex"))
}

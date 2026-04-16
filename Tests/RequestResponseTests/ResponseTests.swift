import Testing
import Foundation
@testable import RequestResponse

@Test func response_statusCodeAndMap() throws {
    let url = URL(string: "https://example.org/v1")!
    let http = try #require(HTTPURLResponse(
        url: url,
        statusCode: 201,
        httpVersion: nil,
        headerFields: nil
    ))

    let response = Response(value: 10, data: Data([1, 2]), response: http)
    #expect(response.statusCode == 201)

    let mapped = response.map { "\($0)" }
    #expect(mapped.value == "10")
    #expect(mapped.data == response.data)
    #expect(mapped.statusCode == 201)
}

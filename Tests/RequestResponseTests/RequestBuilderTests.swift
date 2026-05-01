import Testing
import Foundation
import RequestResponse

@Test func requestBuilder_url_joinsPathAndQuery() throws {
    let builder = RequestBuilder(baseURL: URL(string: "https://example.org/root/")!, encoder: JSONEncoder())
    let request = Request<String>(
        path: "v1/session",
        query: [("a", "1"), ("empty", nil)]
    )

    let url = try builder.url(for: request)
    #expect(url.absoluteString == "https://example.org/root/v1/session?a=1&empty")
}

@Test func requestBuilder_urlRequest_setsDefaultsAndBody() async throws {
    let builder = RequestBuilder(baseURL: URL(string: "https://example.org/")!, encoder: JSONEncoder())
    let request = Request<String>(
        path: "v1/session",
        method: .post,
        body: TestPayload(id: 42)
    )

    let urlRequest = try await builder.urlRequest(for: request)
    #expect(urlRequest.httpMethod == "POST")
    #expect(urlRequest.value(forHTTPHeaderField: "Accept") == "application/json")
    #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
    #expect(urlRequest.httpBody != nil)
}

@Test func requestBuilder_urlRequest_respectsSessionDefaultHeaders() async throws {
    let builder = RequestBuilder(
        baseURL: URL(string: "https://example.org/")!,
        encoder: JSONEncoder(),
        sessionDefaultHeaders: ["Accept": "application/custom", "Content-Type": "application/custom"]
    )
    let request = Request<String>(path: "v1/session", method: .post, body: TestPayload(id: 7))

    let urlRequest = try await builder.urlRequest(for: request)
    #expect(urlRequest.value(forHTTPHeaderField: "Accept") == nil)
    #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == nil)
}

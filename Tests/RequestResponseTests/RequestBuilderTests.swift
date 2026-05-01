import Testing
import Foundation
import EncodeDecode
import RequestResponse

private struct TestPayload: Codable, Sendable {
    let id: Int
}

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

// httpbin.org/post returns JSON, where original body in "json" field
struct HttpBinResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let json: T
}

func httpbinEcho<T: Decodable & Sendable>(for request: Request<T>) async throws -> Response<T> {
    let httpBinURL = URL(string: "https://httpbin.org")!
    let builder = RequestBuilder(baseURL: httpBinURL, encoder: JSONEncoder())
    let urlRequest = try await builder.urlRequest(for: request)
    let (data, urlResponse) = try await URLSession.shared.data(for: urlRequest)
    let value: T = try await decodeBody(data, using: JSONDecoder())
    return Response(value: value, data: data, response: urlResponse)
}

@Test(.disabled("Integration test"))
func requestBuilder_realUsage() async throws {
    //GIVEN
    let request = Request<HttpBinResponse<TestPayload>>(
        path: "post",
        method: .post,
        body: TestPayload(id: 42)
    )
    //WHEN
    let result = try await httpbinEcho(for: request)
    
    //THEN
    #expect(result.response as? HTTPURLResponse != nil)
    #expect(result.statusCode == 200)
    #expect(result.value.json.id == 42)
}

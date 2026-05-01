import Testing
import Foundation
import RequestResponse

// httpbin.org/post returns JSON, where original body in "json" field
struct HttpBinResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let json: T
}

func httpbinEcho<T: Decodable & Sendable>(for request: Request<T>) async throws -> Response<T> {
    let httpBinURL = URL(string: "https://httpbin.org")!
    let builder = RequestBuilder(baseURL: httpBinURL, encoder: JSONEncoder())
    let urlRequest = try await builder.urlRequest(for: request)
    let (data, urlResponse) = try await URLSession.shared.data(for: urlRequest)
    let value: T = try JSONDecoder().decode(T.self, from: data)
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

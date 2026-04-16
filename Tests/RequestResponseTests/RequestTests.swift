import Testing
@testable import RequestResponse

@Test func request_emptyPathNormalizesToSlash() {
    let request = Request<String>(path: "")
    #expect(request.path == "/")
}

@Test func requestVoidInitializer_works() {
    let request = Request<Void>(path: "v1/session")
    #expect(request.path == "v1/session")
}

@Test func httpMethod_stringLiteralAndRawValue() {
    let method: HTTPMethod = "CUSTOM"
    #expect(method.rawValue == "CUSTOM")
    #expect(HTTPMethod.get.rawValue == "GET")
}

import Foundation

/// Builds resolved URLs and `URLRequest` values from a ``Request`` and client context (base URL, encoder, default headers).
public struct RequestBuilder: Sendable {
    public let baseURL: URL
    public let encoder: JSONEncoder
    /// Values from `URLSessionConfiguration.httpAdditionalHeaders`, used for default Content-Type / Accept checks.
    public let sessionDefaultHeaders: [String: String]?

    private let encodeBody: @Sendable (any Encodable & Sendable, JSONEncoder) async throws -> Data?

    /// Same behavior as the public `encodeBody` in the EncodeDecode module, duplicated here so RequestResponse does not depend on that target.
    public static func defaultEncodeBody(_ value: any Encodable & Sendable, _ encoder: JSONEncoder) async throws -> Data? {
        if let data = value as? Data {
            return data
        }
        if let string = value as? String {
            return string.data(using: .utf8)
        }
        return try await Task.detached {
            try encoder.encode(value)
        }.value
    }

    public init(
        baseURL: URL,
        encoder: JSONEncoder,
        sessionDefaultHeaders: [String: String]? = nil,
        encodeBody: @escaping @Sendable (any Encodable & Sendable, JSONEncoder) async throws -> Data? = RequestBuilder.defaultEncodeBody
    ) {
        self.baseURL = baseURL
        self.encoder = encoder
        self.sessionDefaultHeaders = sessionDefaultHeaders
        self.encodeBody = encodeBody
    }

    public func url<T>(for request: Request<T>) throws -> URL {
        let baseFix = baseURL.absoluteString.hasSuffix("/")
            ? baseURL.absoluteString
            : baseURL.absoluteString + "/"
        let pathFix = request.path.hasPrefix("/")
            ? String(request.path.dropFirst())
            : request.path
        let resultUrl = URL(string: baseFix + pathFix)

        guard let url = resultUrl, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        if let query = request.query, !query.isEmpty {
            components.queryItems = query.map(URLQueryItem.init)
        }
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        return url
    }

    public func urlRequest<T>(for request: Request<T>) async throws -> URLRequest {
        let url = try url(for: request)
        var urlRequest = URLRequest(url: url)
        urlRequest.allHTTPHeaderFields = request.headers
        urlRequest.httpMethod = request.method.rawValue
        if let body = request.body {
            urlRequest.httpBody = try await encodeBody(body, encoder)
            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil,
               sessionDefaultHeaders?["Content-Type"] == nil {
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }
        if urlRequest.value(forHTTPHeaderField: "Accept") == nil,
           sessionDefaultHeaders?["Accept"] == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        }
        return urlRequest
    }
}

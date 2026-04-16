import Foundation

/// Builds resolved URLs and `URLRequest` values from a ``Request`` and client context (base URL, encoder, default headers).
public struct RequestBuilder: Sendable {
    public let baseURL: URL
    public let encoder: JSONEncoder
    /// Values from `URLSessionConfiguration.httpAdditionalHeaders`, used for default Content-Type / Accept checks.
    public let sessionDefaultHeaders: [String: String]?

    public init(baseURL: URL, encoder: JSONEncoder, sessionDefaultHeaders: [String: String]? = nil) {
        self.baseURL = baseURL
        self.encoder = encoder
        self.sessionDefaultHeaders = sessionDefaultHeaders
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
            urlRequest.httpBody = try await encodeBody(body, using: encoder)
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

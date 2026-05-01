# RequestResponse

Small Swift package for modeling HTTP calls with a typed `Request<Response>`, building `URL` / `URLRequest` with `RequestBuilder`, and wrapping results in `Response<T>`.

## Requirements

- **Swift 6.1+** (`swift-tools-version: 6.1`; newer toolchains such as 6.2 are fine).
- Platforms in `Package.swift`: iOS 15+, tvOS 15+, macOS 13+, watchOS 9+, visionOS 1+.

## Installation (SPM)

```swift
dependencies: [
    .package(url: "https://github.com/avgx/RequestResponse.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [.product(name: "RequestResponse", package: "RequestResponse")]
    ),
]
```

## Overview

| Type | Role |
|------|------|
| `Request<Response>` | Method, path (relative to a base URL), query, optional body (`Encodable`), headers |
| `RequestBuilder` | Resolves `baseURL` + path + query → `URL`, and → `URLRequest` with optional default `Content-Type` / `Accept` |
| `Response<T>` | Typed value plus raw `Data` and `URLResponse` (e.g. HTTP status) |

The `Response` generic is for type flow at the call site; it does not change how URLs or bodies are built.

## `RequestBuilder` and body encoding

`RequestBuilder` does **not** hold a `JSONEncoder`. You supply how bodies become `Data`:

1. **`RequestBuilder.json(baseURL:encoder:sessionDefaultHeaders:)`** — `Data` and `String` pass through unchanged; any other `Encodable` is encoded with your `JSONEncoder` inside a detached task (same idea as typical REST clients).

2. **`RequestBuilder(baseURL:sessionDefaultHeaders:encodeBody:)`** — general-purpose: `encodeBody` is `@Sendable (Encodable & Sendable) async throws -> Data?`. Use this for YAML, CBOR, form encoding, etc., by capturing whatever encoders you need in the closure.

Default headers when building `URLRequest`:

- If there is a **body**, `Content-Type` is set to `application/json` when neither the request nor `sessionDefaultHeaders` already set it.
- `Accept` is set to `application/json` when not already set on the request or in `sessionDefaultHeaders`.
- Pass `URLSessionConfiguration.httpAdditionalHeaders` as `sessionDefaultHeaders` if the session already defines `Accept` / `Content-Type` and you want the builder **not** to overwrite them.

### Example

```swift
import Foundation
import RequestResponse

struct SessionBody: Codable, Sendable {
    var username: String
    var password: String
}

let encoder = JSONEncoder()
let base = URL(string: "https://example.org/api/")!
let builder = RequestBuilder.json(baseURL: base, encoder: encoder)

let request = Request<String>(
    path: "v1/session",
    method: .post,
    query: [("ref", "abc")],
    body: SessionBody(username: "u", password: "p")
)

let url = try builder.url(for: request)
let urlRequest = try await builder.urlRequest(for: request)
```

### URL and query rules

- The builder concatenates `baseURL.absoluteString` with the request path. A trailing `/` on the base and a path without a leading `/` avoids double slashes.
- Query items use `URLComponents`. A `nil` value in `(String, String?)` yields a key with no `=` value (e.g. `?a=1&empty`).

## `Request` model

- **`body`** — `(any Encodable & Sendable)?` for strict concurrency when encoding off the main actor.
- **`HTTPMethod`** — `ExpressibleByStringLiteral` plus common constants (`GET`, `POST`, …).

## `Response` wrapper

After `URLSession` returns `(Data, URLResponse)`, attach a decoded value:

```swift
struct MyModel: Decodable, Sendable {
    var id: Int
}

let decoded = try JSONDecoder().decode(MyModel.self, from: data)
let response = Response(value: decoded, data: data, response: urlResponse)
let code = response.statusCode
let mapped = response.map { $0.id }
```

Decoding is not part of this package; use `JSONDecoder`, another codec library, or your own helpers.

## Integration sample (httpbin)

The disabled test `requestBuilder_realUsage` in [`Tests/RequestResponseTests/IntegrationTests.swift`](Tests/RequestResponseTests/IntegrationTests.swift) POSTs JSON to [https://httpbin.org/post](https://httpbin.org/post); the JSON body is echoed under a `json` field. The test stays disabled because it requires network access.

## Continuous integration

Workflows live under `.github/workflows/` and use **Swift 6.1** on **macOS** (`macos-latest`).

| Workflow | When | What |
|----------|------|------|
| **CI** (`ci.yml`) | Push and pull requests to **`main`** | `swift build`, `swift test` |
| **Release** (`release.yml`) | Tag **`v*.*.*`** (e.g. `v1.2.0`) | `swift build -c release`, `swift test`, then a GitHub Release with generated notes |

## License

MIT. See the LICENSE file.

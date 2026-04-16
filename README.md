# RequestResponse

RequestResponse provides a clear and convenient API for modeling network requests using `Request<Response>` type.
And its `RequestBuilder` makes it easy to create `URL` or `URLRequest`.

## Requirements

- **Swift 6.1+** (package manifest uses `swift-tools-version: 6.1`; newer toolchains such as 6.2 are fine).
- Platforms declared in `Package.swift`: iOS 15+, tvOS 15+, macOS 13+, watchOS 9+, visionOS 1+.


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

| Piece | Role |
|--------|------|
| `Request<Response>` | Method, path (relative to a base URL), query, optional JSON body, headers |
| `RequestBuilder` | Joins `baseURL` + path + query → `URL`, and → `URLRequest` with JSON `Content-Type` / `Accept` when appropriate |
| `Response<T>` | Decoded value plus raw `Data` and `URLResponse` (e.g. status code) |
| `encodeBody` / `decodeBody` | JSON encoding/decoding with special cases for `Data`, `String`, and empty body → optional `nil` |


## Building URLs and `URLRequest`

Create a builder. 
Build requests.

```swift
struct SessionBody: Codable, Sendable {
    var username: String
    var password: String
}

let encoder = JSONEncoder()
let base = try URL(string: "https://example.org/")!.resolvingRoot("//example.org/tpan1/demo/webclient/")
let builder = RequestBuilder(baseURL: base, encoder: encoder)

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

- `RequestBuilder` concatenates `baseURL.absoluteString` with the request path; a trailing `/` on the base and no leading `/` on the path avoids double slashes.
- Query items are built with `URLComponents`; `nil` values produce keys without values (e.g. `empty` in `?a=1&empty`).

### Headers and JSON defaults

- If the request has a **body**, `Content-Type` is set to `application/json` when neither the request nor `sessionDefaultHeaders` already set it.
- `Accept` is set to `application/json` when not already set on the request or in `sessionDefaultHeaders`.
- Pass `URLSessionConfiguration.httpAdditionalHeaders` into `sessionDefaultHeaders` if the session already defines `Accept` / `Content-Type` and you want the builder to **not** override them.

## Request model

- **`Request<Response>`** — the `Response` type parameter is for documentation/type flow only; it does not affect encoding.
- **`body`** — `(any Encodable & Sendable)?`, matching strict concurrency when encoding off the main actor.
- **`HTTPMethod`** — string literal and common constants (GET, POST, …).

## Response wrapper

After you receive `(Data, URLResponse)` from the session, wrap a decoded value:

```swift
struct MyModel: Decodable, Sendable {
    var id: Int
}

let decoded: MyModel = try await decodeBody(data, using: JSONDecoder())
let response = Response(value: decoded, data: data, response: urlResponse)
let code = response.statusCode
let mapped = response.map { $0.id }
```

## Body encoding and decoding

- **`encodeBody`** — `Data` and `String` pass through; other values are JSON-encoded (asynchronously via `Task.detached`).
- **`decodeBody`** — `Data` / `String` shortcuts; empty `Data` decodes to `nil` when the target type is an **optional** (via `OptionalDecoding`); otherwise JSON decode.

Decoded generic types must be **`Decodable & Sendable`** (Swift 6).

## Continuous integration

Workflows are under `.github/workflows/` and use **Swift 6.1** on **macOS** only (`macos-latest`).

| Workflow | When it runs | What it does |
|----------|----------------|----------------|
| **CI** (`ci.yml`) | Push and pull requests to **`main`** | `swift build` and `swift test` |
| **Release** (`release.yml`) | Push of a git tag matching **`v*.*.*`** (e.g. `v1.2.0`) | `swift build -c release`, `swift test`, then a **GitHub Release** with auto-generated notes |

## License

RequestResponse is available under the MIT license. See the LICENSE file for more info.

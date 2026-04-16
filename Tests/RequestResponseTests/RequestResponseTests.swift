import Testing
import Foundation
@testable import RequestResponse

@Test func testResolveProtocolRelativeWithSameHostAndPortPath() async throws {
    // База, с которой приходит scheme (https) для protocol-relative URL.
    let schemeReference = URL(string: "https://net.digital")!

    // Строка от метода discovery (часто protocol-relative).
    let discovery = "//net.digital:443/tpan1/12_1_bmyolk/webclient/"

    let resolved = try RootURL.resolve(discovery, schemeReference: schemeReference)

    // После resolve корень нормализуется с завершающим `/` (удобно для RequestBuilder).
    let expected = URL(string: "https://net.digital:443/tpan1/12_1_bmyolk/webclient/")!
    #expect(resolved.absoluteString == expected.absoluteString)

    // Пример: дальше все пути относительно этого корня.
    let encoder = JSONEncoder()
    let builder = try RequestBuilder.withResolvedRoot(
        discoveryRoot: discovery,
        schemeReference: schemeReference,
        encoder: encoder
    )
    let apiURL = try builder.url(for: Request<String>(path: "v1/session"))
    #expect(apiURL.absoluteString == "https://net.digital:443/tpan1/12_1_bmyolk/webclient/v1/session")
}

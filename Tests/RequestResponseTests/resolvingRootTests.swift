import Testing
import Foundation
@testable import RequestResponse

@Test func resolvingRoot_protocolRelative_usesReferenceSchemeAndNormalizes() throws {
    let cloud = URL(string: "https://example.org/")!
    let resolved = try cloud.resolvingRoot("//example.org/v1/session")

    #expect(resolved == URL(string: "https://example.org/v1/session/")!)
}

@Test func resolvingRoot_pathOnly_usesReferenceHostAndScheme() throws {
    let cloud = URL(string: "https://example.org/base")!
    let resolved = try cloud.resolvingRoot("/v1/session")

    #expect(resolved == URL(string: "https://example.org/v1/session/")!)
}

@Test func resolvingRoot_absolute_worksAsIsAndNormalizes() throws {
    let cloud = URL(string: "https://example.org/")!
    let resolved = try cloud.resolvingRoot("http://api.example.org/v2")

    #expect(resolved == URL(string: "http://api.example.org/v2/")!)
}

@Test func normalizedDirectoryBase_doesNotChangeQueryAndFragment() {
    let withQuery = URL(string: "https://example.org/v1?a=1")!
    let withFragment = URL(string: "https://example.org/v1#part")!

    #expect(withQuery.normalizedDirectoryBase() == withQuery)
    #expect(withFragment.normalizedDirectoryBase() == withFragment)
}

@Test func resolvingRootIfPresent_handlesNilAndBlank() {
    let cloud = URL(string: "https://example.org/")!

    #expect(cloud.resolvingRootIfPresent(nil) == nil)
    #expect(cloud.resolvingRootIfPresent("   ") == nil)
}

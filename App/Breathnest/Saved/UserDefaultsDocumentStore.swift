import BreathnestKit
import Foundation

/// A `DocumentStore` over one `UserDefaults` key (ADR 0003). A value that is not `Data` reads as bytes that cannot
/// be decoded, so the Kit keeps it under `<key>.unreadable` and falls back to the default.
// `@unchecked`: `UserDefaults` is documented as thread safe but is not marked `Sendable` in the SDK.
struct UserDefaultsDocumentStore: DocumentStore, @unchecked Sendable {
    let defaults: UserDefaults
    let key: String

    func load() throws -> Data? {
        switch defaults.object(forKey: key) {
        case nil: nil
        case let data as Data: data
        default: Data()
        }
    }

    func save(_ data: Data) throws {
        defaults.set(data, forKey: key)
    }

    func setAside() throws {
        defaults.set(defaults.object(forKey: key), forKey: key + ".unreadable")
    }
}

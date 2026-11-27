import BreathnestKit
import Foundation

/// A `DocumentStore` over one JSON file in `Application Support/Breathnest/` (ADR 0003). Writes are atomic. The
/// code reads no file timestamp, size or free space, so the privacy manifest needs no extra category.
struct FileDocumentStore: DocumentStore {
    let url: URL
    /// Names the set-aside copy, `<name>.unreadable-<stamp>.json`. Never read from the file itself.
    var stamp: @Sendable () -> String = { ISO8601DateFormatter().string(from: Date()) }

    static var customExercises: FileDocumentStore {
        let base = URL.applicationSupportDirectory.appending(path: "Breathnest", directoryHint: .isDirectory)
        return FileDocumentStore(url: base.appending(path: "custom-exercises.json"))
    }

    static var reminders: FileDocumentStore {
        let base = URL.applicationSupportDirectory.appending(path: "Breathnest", directoryHint: .isDirectory)
        return FileDocumentStore(url: base.appending(path: "reminders.json"))
    }

    func load() throws -> Data? {
        do {
            return try Data(contentsOf: url)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile || error.code == .fileNoSuchFile {
            return nil
        }
    }

    func save(_ data: Data) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    func setAside() throws {
        let name = url.deletingPathExtension().lastPathComponent
        let target = url.deletingLastPathComponent().appending(path: "\(name).unreadable-\(stamp()).json")
        try FileManager.default.moveItem(at: url, to: target)
    }
}

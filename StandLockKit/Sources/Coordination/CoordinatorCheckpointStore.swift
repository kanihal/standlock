import Foundation

/// The consumed recovery record and its statistics share a single atomic write.
public struct CoordinatorCheckpointStore: Sendable {
    public let url: URL
    private var backupURL: URL { url.appendingPathExtension("previous") }

    public init(url: URL) { self.url = url }

    public func load() throws -> CoordinatorCheckpoint? {
        var failure: (any Error)?
        for candidate in [url, backupURL] where FileManager.default.fileExists(atPath: candidate.path) {
            do { return try JSONDecoder().decode(CoordinatorCheckpoint.self, from: Data(contentsOf: candidate)) }
            catch { failure = error }
        }
        if let failure { throw failure }
        return nil
    }

    public func save(_ checkpoint: CoordinatorCheckpoint) throws {
        let data = try JSONEncoder().encode(checkpoint)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if let previous = try? Data(contentsOf: url),
           (try? JSONDecoder().decode(CoordinatorCheckpoint.self, from: previous)) != nil {
            try previous.write(to: backupURL, options: .atomic)
        }
        try data.write(to: url, options: .atomic)
    }
}

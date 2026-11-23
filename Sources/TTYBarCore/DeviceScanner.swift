import Foundation

/// Source of candidate device paths.
public protocol DeviceScanner: Sendable {
    /// Full paths of the entries directly inside the scanned directory.
    func devicePaths() -> [String]
}

/// Lists the top-level entries of a directory (by default `/dev`) without opening them.
public struct DirectoryScanner: DeviceScanner {
    public let directory: String

    public init(directory: String = "/dev") {
        self.directory = directory
    }

    public func devicePaths() -> [String] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory)) ?? []
        let base = directory.hasSuffix("/") ? directory : directory + "/"
        return names.map { base + $0 }
    }
}

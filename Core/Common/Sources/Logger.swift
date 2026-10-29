import os

/// The logging contract every Base module that logs depends on.
///
/// A product supplies exactly one implementation: ``OSLogLogger`` for debug builds,
/// ``NoOpLogger`` (or its own crash-reporter-backed logger) for release.
public protocol Logger: Sendable {
    func debug(_ tag: String, _ message: String)
    func info(_ tag: String, _ message: String)
    func warning(_ tag: String, _ message: String, error: (any Error)?)
    func error(_ tag: String, _ message: String, error: (any Error)?)
}

extension Logger {
    public func warning(_ tag: String, _ message: String) {
        warning(tag, message, error: nil)
    }

    public func error(_ tag: String, _ message: String) {
        error(tag, message, error: nil)
    }
}

/// Writes to the unified logging system (Console.app, Xcode console).
///
/// Messages are logged `.public` because the Base only ever logs its own diagnostic text —
/// never user content. A product that logs user content through this must not use it in release.
public struct OSLogLogger: Logger {
    private let subsystem: String

    public init(subsystem: String) {
        self.subsystem = subsystem
    }

    public func debug(_ tag: String, _ message: String) {
        os.Logger(subsystem: subsystem, category: tag).debug("\(message, privacy: .public)")
    }

    public func info(_ tag: String, _ message: String) {
        os.Logger(subsystem: subsystem, category: tag).info("\(message, privacy: .public)")
    }

    public func warning(_ tag: String, _ message: String, error: (any Error)?) {
        os.Logger(subsystem: subsystem, category: tag)
            .warning("\(Self.format(message, error), privacy: .public)")
    }

    public func error(_ tag: String, _ message: String, error: (any Error)?) {
        os.Logger(subsystem: subsystem, category: tag)
            .error("\(Self.format(message, error), privacy: .public)")
    }

    private static func format(_ message: String, _ error: (any Error)?) -> String {
        guard let error else { return message }
        return "\(message): \(String(describing: error))"
    }
}

/// Discards everything. For release builds, and for tests that do not assert on logging.
public struct NoOpLogger: Logger {
    public init() {}

    public func debug(_ tag: String, _ message: String) {}
    public func info(_ tag: String, _ message: String) {}
    public func warning(_ tag: String, _ message: String, error: (any Error)?) {}
    public func error(_ tag: String, _ message: String, error: (any Error)?) {}
}

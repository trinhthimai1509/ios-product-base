import Foundation
import Observation
import ProductBaseCommon
import ProductBasePreferences

/// In-memory ``AppPreferences`` for tests and SwiftUI previews.
@MainActor
@Observable
public final class FakeAppPreferences: AppPreferences {
    public private(set) var themeMode: ThemeMode
    public private(set) var onboardingCompleted: Bool
    public private(set) var notificationsEnabled: Bool

    public init(
        themeMode: ThemeMode = .system,
        onboardingCompleted: Bool = false,
        notificationsEnabled: Bool = true
    ) {
        self.themeMode = themeMode
        self.onboardingCompleted = onboardingCompleted
        self.notificationsEnabled = notificationsEnabled
    }

    public func setThemeMode(_ themeMode: ThemeMode) { self.themeMode = themeMode }
    public func setOnboardingCompleted(_ completed: Bool) { onboardingCompleted = completed }
    public func setNotificationsEnabled(_ enabled: Bool) { notificationsEnabled = enabled }
}

/// A ``PremiumState`` a test can drive.
@MainActor
@Observable
public final class FakePremiumState: PremiumState {
    public var status: PremiumStatus

    public init(status: PremiumStatus = .unknown) {
        self.status = status
    }
}

/// A ``Logger`` that remembers what it was told, for asserting that a failure was logged.
public final class RecordingLogger: Logger, @unchecked Sendable {
    public struct Entry: Equatable, Sendable {
        public enum Level: Sendable { case debug, info, warning, error }
        public let level: Level
        public let tag: String
        public let message: String
    }

    private let lock = NSLock()
    private var storage: [Entry] = []

    public init() {}

    public var entries: [Entry] {
        lock.withLock { storage }
    }

    public func debug(_ tag: String, _ message: String) { append(.debug, tag, message) }
    public func info(_ tag: String, _ message: String) { append(.info, tag, message) }

    public func warning(_ tag: String, _ message: String, error: (any Error)?) {
        append(.warning, tag, message)
    }

    public func error(_ tag: String, _ message: String, error: (any Error)?) {
        append(.error, tag, message)
    }

    private func append(_ level: Entry.Level, _ tag: String, _ message: String) {
        lock.withLock { storage.append(Entry(level: level, tag: tag, message: message)) }
    }
}

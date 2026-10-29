import Foundation
import ProductBaseCommon
import UserNotifications

/// Where the user stands on notifications. iOS has no channels; this plus the app's own
/// `notificationsEnabled` preference is the whole picture.
public enum NotificationAuthorization: Sendable, Equatable {
    case notDetermined
    case denied
    case authorized
    /// Delivered quietly to Notification Center until the user decides.
    case provisional
    case ephemeral

    /// Whether a scheduled notification would be delivered.
    public var canDeliver: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral: true
        case .notDetermined, .denied: false
        }
    }

    init(_ status: UNAuthorizationStatus) {
        switch status {
        case .notDetermined: self = .notDetermined
        case .denied: self = .denied
        case .authorized: self = .authorized
        case .provisional: self = .provisional
        case .ephemeral: self = .ephemeral
        @unknown default: self = .denied
        }
    }
}

/// The system permission. Ask from a moment where the value is obvious to the user — never on
/// first launch. Once denied, iOS will not ask again; send the user to Settings instead.
public protocol NotificationPermission: Sendable {
    func status() async -> NotificationAuthorization
    /// Shows the system prompt if the user has not decided yet. Returns whether delivery is allowed.
    func request() async -> Bool
}

public struct UserNotificationPermission: NotificationPermission {
    private let options: UNAuthorizationOptions
    private let logger: any Logger

    public init(options: UNAuthorizationOptions = [.alert, .sound, .badge], logger: any Logger) {
        self.options = options
        self.logger = logger
    }

    public func status() async -> NotificationAuthorization {
        NotificationAuthorization(await UNUserNotificationCenter.current().notificationSettings().authorizationStatus)
    }

    public func request() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        } catch {
            logger.warning("Notifications", "Authorization request failed", error: error)
            return false
        }
    }
}

/// A local reminder. Scheduling another with the same ``id`` replaces it.
public struct ReminderRequest: Sendable, Equatable {
    public var id: String
    public var triggerDate: Date
    /// When set, the reminder recurs on these date components (e.g. `[.hour, .minute]` for daily).
    public var repeatMatching: Set<Calendar.Component>?
    public var title: String
    public var body: String
    /// Groups notifications in Notification Center — the nearest thing iOS has to a channel.
    public var threadIdentifier: String?
    /// Delivered back in `userInfo`; read it with ``ReminderRequest/deepLink(from:)``.
    public var deepLink: URL?
    public var playsSound: Bool

    public init(
        id: String,
        triggerDate: Date,
        repeatMatching: Set<Calendar.Component>? = nil,
        title: String,
        body: String,
        threadIdentifier: String? = nil,
        deepLink: URL? = nil,
        playsSound: Bool = true
    ) {
        self.id = id
        self.triggerDate = triggerDate
        self.repeatMatching = repeatMatching
        self.title = title
        self.body = body
        self.threadIdentifier = threadIdentifier
        self.deepLink = deepLink
        self.playsSound = playsSound
    }

    static let deepLinkKey = "productbase.deepLink"

    /// The deep link of a delivered reminder, from `UNNotificationResponse`'s
    /// `notification.request.content.userInfo`.
    public static func deepLink(from userInfo: [AnyHashable: Any]) -> URL? {
        (userInfo[deepLinkKey] as? String).flatMap(URL.init(string:))
    }
}

/// Schedules local reminders. iOS keeps at most 64 pending; schedule the nearest ones.
public protocol ReminderScheduler: Sendable {
    func schedule(_ request: ReminderRequest) async throws
    func cancel(id: String) async
    func pendingIDs() async -> [String]
}

public struct UserNotificationReminderScheduler: ReminderScheduler {
    private let calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    public func schedule(_ request: ReminderRequest) async throws {
        try await UNUserNotificationCenter.current().add(Self.makeRequest(request, calendar: calendar))
    }

    public func cancel(id: String) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.removeDeliveredNotifications(withIdentifiers: [id])
    }

    public func pendingIDs() async -> [String] {
        await UNUserNotificationCenter.current().pendingNotificationRequests().map(\.identifier)
    }

    /// Pure, so the mapping is testable without the notification center.
    static func makeRequest(_ request: ReminderRequest, calendar: Calendar) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        if let thread = request.threadIdentifier {
            content.threadIdentifier = thread
        }
        if request.playsSound {
            content.sound = .default
        }
        if let deepLink = request.deepLink {
            content.userInfo = [ReminderRequest.deepLinkKey: deepLink.absoluteString]
        }

        let components: Set<Calendar.Component> =
            request.repeatMatching ?? [.year, .month, .day, .hour, .minute, .second]
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: calendar.dateComponents(components, from: request.triggerDate),
            repeats: request.repeatMatching != nil
        )
        return UNNotificationRequest(identifier: request.id, content: content, trigger: trigger)
    }
}

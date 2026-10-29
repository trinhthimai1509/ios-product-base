import Foundation
import Testing
import UserNotifications

@testable import ProductBaseNotification

struct ReminderRequestTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    @Test func oneOffReminderTriggersOnceAtTheExactTime() throws {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let request = UserNotificationReminderScheduler.makeRequest(
            ReminderRequest(id: "daily", triggerDate: date, title: "T", body: "B"),
            calendar: calendar
        )

        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(request.identifier == "daily")
        #expect(!trigger.repeats)
        #expect(calendar.date(from: trigger.dateComponents) == date)
        #expect(request.content.sound != nil)
    }

    @Test func repeatingReminderMatchesOnlyTheGivenComponents() throws {
        let request = UserNotificationReminderScheduler.makeRequest(
            ReminderRequest(
                id: "r", triggerDate: Date(timeIntervalSince1970: 0), repeatMatching: [.hour, .minute],
                title: "T", body: "B", playsSound: false
            ),
            calendar: calendar
        )

        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(trigger.repeats)
        #expect(trigger.dateComponents.hour == 0)
        #expect(trigger.dateComponents.day == nil)
        #expect(request.content.sound == nil)
    }

    @Test func deepLinkRoundTripsThroughUserInfo() {
        let url = URL(string: "demo://today")!
        let request = UserNotificationReminderScheduler.makeRequest(
            ReminderRequest(id: "d", triggerDate: .now, title: "T", body: "B", deepLink: url),
            calendar: calendar
        )

        #expect(ReminderRequest.deepLink(from: request.content.userInfo) == url)
    }

    @Test func onlyGrantedStatesCanDeliver() {
        #expect(NotificationAuthorization.authorized.canDeliver)
        #expect(NotificationAuthorization.provisional.canDeliver)
        #expect(!NotificationAuthorization.denied.canDeliver)
        #expect(!NotificationAuthorization.notDetermined.canDeliver)
    }
}

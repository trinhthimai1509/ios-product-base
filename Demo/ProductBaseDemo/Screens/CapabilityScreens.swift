import ProductBaseAds
import ProductBaseDesignSystem
import ProductBaseNetwork
import ProductBaseNotification
import ProductBaseTelemetry
import SwiftData
import SwiftUI

struct MonetisationScreen: View {
    let container: AppContainer

    @State private var lastResult = "—"

    var body: some View {
        let ads = container.ads
        List {
            Section("State") {
                LabeledContent("Premium", value: "\(container.billing.status)")
                LabeledContent("Ads available", value: ads.adsAvailable ? "Yes" : "No")
                LabeledContent("Privacy options required", value: ads.privacyOptionsRequired ? "Yes" : "No")
                LabeledContent("Last result", value: lastResult)
            }
            Section {
                Button("Record a qualifying action") { ads.recordQualifyingAction() }
                Button("Show interstitial") { Task { lastResult = "\(await ads.showInterstitial())" } }
                Button("Show rewarded") { Task { lastResult = "\(await ads.showRewarded())" } }
            } header: {
                Text("Ads")
            } footer: {
                Text("Interstitials need 3 qualifying actions and 30 s between shows (demo policy).")
            }
            Section("Review") {
                Button("Request review") { lastResult = "\(container.review.requestReview())" }
            }
        }
        .navigationTitle("Ads & review")
    }
}

private struct Post: Decodable, Identifiable {
    let id: Int
    let title: String
}

struct NetworkScreen: View {
    let container: AppContainer

    @State private var posts: [Post] = []
    @State private var error: NetworkError?
    @State private var isLoading = false
    @State private var isOnline = true

    var body: some View {
        Group {
            if isLoading {
                LoadingState(description: "Loading posts")
            } else if let error {
                ErrorState(title: "Couldn't load posts", description: message(for: error), retryTitle: "Retry") {
                    Task { await load() }
                }
            } else {
                List(posts) { Text($0.title) }
            }
        }
        .safeAreaInset(edge: .top) {
            if !isOnline {
                Text("You're offline").font(.footnote.bold()).frame(maxWidth: .infinity)
                    .padding(8).background(.orange.opacity(0.2))
            }
        }
        .navigationTitle("Network")
        .task { await load() }
        .task {
            for await online in container.networkMonitor.isOnline { isOnline = online }
        }
    }

    private func load() async {
        isLoading = true
        error = nil
        do {
            let all: [Post] = try await container.httpClient.send(.get("posts"))
            posts = Array(all.prefix(20))
        } catch {
            self.error = error
        }
        isLoading = false
    }

    private func message(for error: NetworkError) -> String {
        switch error {
        case .noConnection: "You appear to be offline."
        case .timeout: "The server took too long to answer."
        case let .http(status, _): "The server answered \(status)."
        default: "Something went wrong."
        }
    }
}

struct DataScreen: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DemoNote.createdAt, order: .reverse) private var notes: [DemoNote]

    var body: some View {
        Group {
            if notes.isEmpty {
                EmptyState(title: "No notes", description: "Notes persist with SwiftData.", actionTitle: "Add note", action: add)
            } else {
                List {
                    ForEach(notes) { note in
                        LabeledContent(note.text, value: note.createdAt.formatted(date: .omitted, time: .standard))
                    }
                    .onDelete { offsets in offsets.map { notes[$0] }.forEach(context.delete) }
                }
            }
        }
        .navigationTitle("Database")
        .toolbar { Button("Add", systemImage: "plus", action: add) }
    }

    private func add() {
        context.insert(DemoNote(text: "Note #\(notes.count + 1)"))
    }
}

struct InfraScreen: View {
    let container: AppContainer

    @State private var authorization: NotificationAuthorization = .notDetermined
    @State private var pending: [String] = []

    var body: some View {
        List {
            Section("Notifications") {
                LabeledContent("Permission", value: "\(authorization)")
                Button("Request permission") {
                    Task {
                        _ = await container.notificationPermission.request()
                        await refresh()
                    }
                }
                Button("Remind me in 10 seconds") {
                    Task {
                        try? await container.reminders.schedule(
                            ReminderRequest(
                                id: "demo", triggerDate: .now.addingTimeInterval(10),
                                title: "Product Base", body: "This reminder was scheduled 10 seconds ago.",
                                deepLink: URL(string: "productbasedemo://infra")
                            )
                        )
                        await refresh()
                    }
                }
                Button("Cancel reminder", role: .destructive) {
                    Task {
                        await container.reminders.cancel(id: "demo")
                        await refresh()
                    }
                }
                LabeledContent("Pending", value: pending.isEmpty ? "none" : pending.joined(separator: ", "))
            }
            Section("Telemetry") {
                LabeledContent("Firebase configured", value: container.telemetry.isFirebaseConfigured ? "Yes" : "No (no-op)")
                Button("Log sample event") {
                    container.telemetry.analytics.logEvent(AnalyticsEvent("demo_button", parameters: ["screen": "infra"]))
                }
            }
        }
        .navigationTitle("Infrastructure")
        .task { await refresh() }
    }

    private func refresh() async {
        authorization = await container.notificationPermission.status()
        pending = await container.reminders.pendingIDs()
    }
}

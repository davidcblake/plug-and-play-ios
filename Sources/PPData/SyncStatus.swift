import Foundation
import PPCore

/// Whether syncing can happen at all right now.
///
/// Separate from ``SyncActivity`` on purpose: "not syncing because the person
/// is not signed into iCloud" and "not syncing because there is nothing to do"
/// look identical on screen if you collapse them, and only one of the two is
/// worth telling anybody about.
public enum SyncAvailability: Sendable, Equatable {
    /// Signed in, and syncing can happen.
    case ready
    /// No iCloud account on the device. The app still works — everything is on
    /// the phone — but nothing will reach another device.
    case notSignedIn
    /// This app was built or configured to keep its data on this device only.
    case turnedOff
    /// An account exists but something outside the app forbids it: parental
    /// controls, a managed device, iCloud Drive switched off.
    case restricted
    /// Nobody has asked yet. The state before the first check, not an error.
    case unknown
}

/// What syncing is doing right now.
public enum SyncActivity: Sendable, Equatable {
    /// Nothing to do. The normal state, and the one an app spends its life in.
    case idle
    /// Moving data, in one direction or both.
    case working
    /// The last attempt failed. Local data is untouched and still readable —
    /// this is worth showing quietly, never as something that blocks the app.
    case failed(SyncFailure)
}

/// Why syncing failed, in both the voices `PPCore` requires: one for the person
/// and one for the log.
public struct SyncFailure: PPError, Equatable {
    public let userMessage: String
    public let logMessage: String

    public init(userMessage: String, logMessage: String? = nil) {
        self.userMessage = userMessage
        self.logMessage = logMessage ?? userMessage
    }
}

/// Everything an app can know about syncing, in one value.
///
/// One value rather than three properties, so a view observes one thing and a
/// fake has one thing to set. It is `Equatable` so SwiftUI can tell when
/// nothing has actually changed.
public struct SyncStatus: Sendable, Equatable {
    public var availability: SyncAvailability
    public var activity: SyncActivity
    /// When data last made it to the cloud, as far as *this device* knows.
    ///
    /// `nil` means never, or not since the app was installed. Deliberately not
    /// "when the server last changed" — this device cannot know that offline,
    /// and a local-first app must be able to answer this with no network.
    public var lastSynced: Date?

    public init(
        availability: SyncAvailability = .unknown,
        activity: SyncActivity = .idle,
        lastSynced: Date? = nil
    ) {
        self.availability = availability
        self.activity = activity
        self.lastSynced = lastSynced
    }

    /// Whether anything is worth saying to the person using the app.
    ///
    /// The answer is no far more often than people expect, which is the point:
    /// a local-first app that keeps announcing its sync state is telling on
    /// itself. Nothing here blocks a screen — the data is already on the phone.
    public var isWorthMentioning: Bool {
        switch availability {
        case .notSignedIn, .restricted:
            return true
        case .ready, .turnedOff, .unknown:
            if case .failed = activity { return true }
            return false
        }
    }
}

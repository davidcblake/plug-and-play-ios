import Foundation

/// The seam between an app and whatever is syncing its data.
///
/// `docs/decisions/0002-local-first-with-cloudkit.md` says feature code never
/// imports CloudKit. This is the whole of what it talks to instead.
///
/// **It has no `sync()` method, and that is not an oversight.** SwiftData
/// mirrors to CloudKit on its own, on a schedule Apple decides. There is
/// nothing to call. What an app genuinely needs is to *ask* — is syncing even
/// possible, is it working, when did it last succeed — so that it can say
/// "sign in to iCloud to see this on your iPad" instead of silently never
/// syncing. An API with a `sync()` that quietly did nothing would be a lie
/// told in a protocol.
///
/// **Nothing here is on the path to reading or writing data.** Saving a trip
/// goes through SwiftData and completes with the phone in airplane mode. This
/// protocol only reports on what happens afterwards, which is what keeps the
/// local-first promise from depending on the network.
public protocol SyncProvider: Sendable {
    /// What syncing is doing, as of now.
    var status: SyncStatus { get }

    /// Status changes, beginning with the current status.
    ///
    /// A function rather than a property because each caller gets its own
    /// stream: two views observing sync must both receive every change, and a
    /// single shared stream would hand each value to whichever one asked first.
    func statusUpdates() -> AsyncStream<SyncStatus>
}

/// A provider for an app that does not sync.
///
/// The default. An app with nothing wired up is not syncing, and this says so
/// plainly rather than claiming to be ready and then never doing anything.
/// Also the right choice for a genuinely local-only app.
public struct NoSyncProvider: SyncProvider {
    public init() {}

    public var status: SyncStatus {
        SyncStatus(availability: .turnedOff, activity: .idle, lastSynced: nil)
    }

    public func statusUpdates() -> AsyncStream<SyncStatus> {
        let current = status
        return AsyncStream { continuation in
            // One value, then done. A stream that stays open forever waiting
            // for changes that cannot happen would leave every `for await`
            // over it hanging at the end of a test.
            continuation.yield(current)
            continuation.finish()
        }
    }
}

import Foundation
import SwiftUI
import Testing
@testable import PPData

@Suite("An app that does not sync")
struct NoSyncProviderTests {
    @Test("Says sync is off rather than pretending to be ready")
    func reportsTurnedOff() {
        let provider = NoSyncProvider()

        #expect(provider.status.availability == .turnedOff)
        #expect(provider.status.activity == .idle)
        #expect(provider.status.lastSynced == nil)
    }

    @Test("Its stream gives the current status and then ends")
    func streamEndsRatherThanHanging() async {
        var received: [SyncStatus] = []
        for await status in NoSyncProvider().statusUpdates() {
            received.append(status)
        }

        // The loop above has to finish. A stream that stayed open waiting for
        // changes that cannot happen would hang this test forever instead of
        // failing it, which is the worst way for a test to be wrong.
        #expect(received.count == 1)
        #expect(received.first?.availability == .turnedOff)
    }
}

@Suite("A sync provider a test controls")
struct InMemorySyncProviderTests {
    @Test("Reports whatever it was given")
    func reportsItsStartingStatus() {
        let provider = InMemorySyncProvider(
            status: SyncStatus(availability: .notSignedIn, activity: .idle)
        )

        #expect(provider.status.availability == .notSignedIn)
    }

    @Test("Defaults to the ordinary case: signed in and quiet")
    func defaultsToReady() {
        #expect(InMemorySyncProvider().status.availability == .ready)
    }

    @Test("A watcher gets the current status, then every change")
    func streamsChanges() async {
        let provider = InMemorySyncProvider(status: SyncStatus(availability: .ready))
        var updates = provider.statusUpdates().makeAsyncIterator()

        let first = await updates.next()
        #expect(first?.availability == .ready)

        provider.update(to: SyncStatus(availability: .notSignedIn))
        let second = await updates.next()
        #expect(second?.availability == .notSignedIn)
    }

    @Test("Two watchers both see the same change")
    func everyWatcherIsTold() async {
        // The reason `statusUpdates()` hands out a fresh stream each time. With
        // one shared stream, whichever view asked first would swallow the
        // update and the second would never redraw.
        let provider = InMemorySyncProvider()
        var watcher = provider.statusUpdates().makeAsyncIterator()
        var otherWatcher = provider.statusUpdates().makeAsyncIterator()

        _ = await watcher.next()
        _ = await otherWatcher.next()

        provider.update(to: SyncStatus(availability: .restricted))

        let watcherSaw = await watcher.next()
        let otherWatcherSaw = await otherWatcher.next()

        #expect(watcherSaw?.availability == .restricted)
        #expect(otherWatcherSaw?.availability == .restricted)
    }

    @Test("Failing leaves everything else about the status alone")
    func failingIsNotSigningOut() {
        let synced = Date(timeIntervalSince1970: 1_000_000)
        let provider = InMemorySyncProvider(
            status: SyncStatus(availability: .ready, activity: .idle, lastSynced: synced)
        )

        provider.fail(SyncFailure(userMessage: "Could not reach iCloud."))

        #expect(provider.status.availability == .ready)
        #expect(provider.status.lastSynced == synced)
        #expect(provider.status.activity == .failed(SyncFailure(userMessage: "Could not reach iCloud.")))
    }
}

@Suite("Injection")
struct SyncProviderEnvironmentTests {
    @Test("A view with nothing wired up is told sync is off")
    func defaultsToNoSync() {
        #expect(EnvironmentValues().syncProvider.status.availability == .turnedOff)
    }

    @Test("An injected provider is what the view tree reads")
    func carriesAnInjectedProvider() {
        var environment = EnvironmentValues()
        environment.syncProvider = InMemorySyncProvider(
            status: SyncStatus(availability: .restricted)
        )

        #expect(environment.syncProvider.status.availability == .restricted)
    }
}

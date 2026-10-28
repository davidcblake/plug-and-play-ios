import Foundation
import SwiftUI
import Testing
@testable import PPCore

@Suite("Assuming there is a connection")
struct AlwaysOnlineTests {
    @Test("Says yes, because being wrong the other way is worse")
    func saysOnline() {
        #expect(AlwaysOnline().isOnline)
    }

    @Test("Its stream gives one answer and then ends")
    func streamEndsRatherThanHanging() async {
        var received: [Bool] = []
        for await online in AlwaysOnline().changes() {
            received.append(online)
        }

        // The loop above has to finish. A stream that stayed open waiting for
        // changes that cannot happen would hang this test forever instead of
        // failing it, which is the worst way for a test to be wrong.
        #expect(received == [true])
    }
}

@Suite("A connection a test controls")
struct InMemoryConnectivityTests {
    @Test("Starts wherever it was put")
    func startsWhereItWasPut() {
        #expect(InMemoryConnectivity(isOnline: false).isOnline == false)
        #expect(InMemoryConnectivity().isOnline)
    }

    @Test("A watcher gets the current answer, then every change", .timeLimit(.minutes(1)))
    func streamsChanges() async {
        let connection = InMemoryConnectivity(isOnline: true)
        var updates = connection.changes().makeAsyncIterator()

        #expect(await updates.next() == true)

        connection.set(isOnline: false)
        #expect(await updates.next() == false)
    }

    @Test("Two watchers both see the change", .timeLimit(.minutes(1)))
    func everyWatcherIsTold() async {
        // The reason `changes()` hands out a fresh stream each time. With one
        // shared stream, whichever view asked first would swallow the update
        // and the second would never redraw.
        let connection = InMemoryConnectivity()
        var watcher = connection.changes().makeAsyncIterator()
        var otherWatcher = connection.changes().makeAsyncIterator()
        _ = await watcher.next()
        _ = await otherWatcher.next()

        connection.set(isOnline: false)

        #expect(await watcher.next() == false)
        #expect(await otherWatcher.next() == false)
    }

    @Test("Saying the same thing twice tells nobody anything", .timeLimit(.minutes(1)))
    func repeatsAreNotChanges() async {
        // A path monitor reports the same state more than once. Passing that
        // on would redraw every watching screen for no reason.
        let connection = InMemoryConnectivity(isOnline: true)
        var updates = connection.changes().makeAsyncIterator()
        _ = await updates.next()

        connection.set(isOnline: true)
        connection.set(isOnline: false)

        #expect(await updates.next() == false)
    }
}

@Suite("Injecting the connection")
struct ConnectivityEnvironmentTests {
    @Test("A view with nothing wired up assumes it is online")
    func defaultsToOnline() {
        #expect(EnvironmentValues().connectivity.isOnline)
    }

    @Test("An injected connection is what the view tree reads")
    func carriesAnInjectedConnection() {
        var environment = EnvironmentValues()
        environment.connectivity = InMemoryConnectivity(isOnline: false)

        #expect(environment.connectivity.isOnline == false)
    }
}

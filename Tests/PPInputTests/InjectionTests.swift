import SwiftUI
import Testing
@testable import PPInput

@Suite("Injection")
struct InjectionTests {
    @Test("A view with nothing wired up gets the inert defaults")
    func defaultsAreInert() {
        let environment = EnvironmentValues()

        #expect(environment.transcriber is NoTranscriber)
        #expect(environment.textRecognizer is NoTextRecognizer)
        #expect(environment.inputPermissions is NoInputPermissions)
    }

    @Test("What is injected is what the view tree reads")
    func injectionCarries() async throws {
        var environment = EnvironmentValues()
        environment.transcriber = InMemoryTranscriber(hears: ["a trip note"])
        environment.textRecognizer = InMemoryTextRecognizer(finds: ["TOTAL"])
        environment.inputPermissions = InMemoryInputPermissions([.microphone: .granted])

        let stream = try await environment.transcriber.startDictation()
        var heard: [Transcript] = []
        for await transcript in stream {
            heard.append(transcript)
        }
        let lines = try await environment.textRecognizer.text(in: Data())

        #expect(heard.map(\.text) == ["a trip note"])
        #expect(lines == ["TOTAL"])
        #expect(environment.inputPermissions.status(of: .microphone) == .granted)
    }
}

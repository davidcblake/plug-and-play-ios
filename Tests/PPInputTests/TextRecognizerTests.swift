import Foundation
import Testing
@testable import PPInput

@Suite("Reading a picture")
struct TextRecognizerTests {
    private let anyPicture = Data([0x01, 0x02, 0x03])

    @Test("Gives back the lines it found, in order")
    func findsLines() async throws {
        let recognizer = InMemoryTextRecognizer(finds: ["TOTAL", "42.00"])

        let lines = try await recognizer.text(in: anyPicture)

        #expect(lines == ["TOTAL", "42.00"])
    }

    @Test("A picture with no words in it is an answer, not a failure")
    func emptyIsNotAnError() async throws {
        // Somebody will photograph a blank wall. That is not a bug and should
        // not be shown as one.
        let lines = try await InMemoryTextRecognizer().text(in: anyPicture)

        #expect(lines.isEmpty)
    }

    @Test("An unreadable picture throws")
    func failsWhenToldTo() async throws {
        let recognizer = InMemoryTextRecognizer(failsWith: .notPermitted)

        do {
            _ = try await recognizer.text(in: anyPicture)
            Issue.record("Reading succeeded when it should have failed")
        } catch let failure as InputFailure {
            #expect(failure == .notPermitted)
        }
    }

    @Test("An app that has not wired this up says so")
    func defaultSaysItIsNotSetUp() async throws {
        do {
            _ = try await NoTextRecognizer().text(in: anyPicture)
            Issue.record("NoTextRecognizer read something")
        } catch let failure as InputFailure {
            #expect(failure == .textRecognitionUnavailable)
        }
    }
}

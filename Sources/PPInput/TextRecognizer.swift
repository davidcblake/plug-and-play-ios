import Foundation

/// Reading the words out of a picture.
///
/// A photographed page, a receipt, a whiteboard, a plaque outside a church.
/// The picture goes in, the lines of text come out, top to bottom.
///
/// **Takes `Data` rather than an image type on purpose.** Nothing in this seam
/// touches UIKit, which `AGENTS.md` allows only behind a justified wrapper, and
/// a test can hand it four bytes without building an image at all.
///
/// This is extraction, not understanding. Reading "TOTAL 42.00" off a receipt
/// belongs here and happens on the device for free. Working out what a
/// photographed menu *means* is a different job for a different seam.
public protocol TextRecognizer: Sendable {
    /// Every line of text found in the picture, in reading order.
    ///
    /// An empty array means the picture had no text in it, which is an ordinary
    /// answer and not a failure.
    ///
    /// - Throws: ``InputFailure`` when the picture could not be read at all.
    func text(in imageData: Data) async throws -> [String]
}

/// Reads nothing, and says so.
///
/// The default, for an app that has not wired this up.
public struct NoTextRecognizer: TextRecognizer {
    public init() {}

    public func text(in imageData: Data) async throws -> [String] {
        throw InputFailure.textRecognitionUnavailable
    }
}

/// Finds exactly the lines you tell it to.
///
/// For building the screen that shows what was read out of a photo, and for
/// testing what happens when a picture turns out to have nothing in it.
public struct InMemoryTextRecognizer: TextRecognizer {
    private let lines: [String]
    private let failure: InputFailure?

    /// - Parameters:
    ///   - lines: What it finds. Empty is a legitimate answer worth testing —
    ///     somebody will photograph a blank wall.
    ///   - failure: When set, reading throws this instead.
    public init(finds lines: [String] = [], failsWith failure: InputFailure? = nil) {
        self.lines = lines
        self.failure = failure
    }

    public func text(in imageData: Data) async throws -> [String] {
        if let failure {
            throw failure
        }
        return lines
    }
}

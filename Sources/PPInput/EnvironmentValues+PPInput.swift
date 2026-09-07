import SwiftUI

// Speaking, photographing and asking permission all travel down the view tree,
// the way everything else in this foundation is injected (`AGENTS.md`:
// environment, never a singleton).

private struct TranscriberKey: EnvironmentKey {
    static let defaultValue: any Transcriber = NoTranscriber()
}

private struct TextRecognizerKey: EnvironmentKey {
    static let defaultValue: any TextRecognizer = NoTextRecognizer()
}

private struct InputPermissionsKey: EnvironmentKey {
    static let defaultValue: any InputPermissions = NoInputPermissions()
}

extension EnvironmentValues {
    /// What turns speech into words for this part of the view tree.
    public var transcriber: any Transcriber {
        get { self[TranscriberKey.self] }
        set { self[TranscriberKey.self] = newValue }
    }

    /// What reads text out of pictures for this part of the view tree.
    public var textRecognizer: any TextRecognizer {
        get { self[TextRecognizerKey.self] }
        set { self[TextRecognizerKey.self] = newValue }
    }

    /// How this part of the view tree asks permission.
    public var inputPermissions: any InputPermissions {
        get { self[InputPermissionsKey.self] }
        set { self[InputPermissionsKey.self] = newValue }
    }
}

extension View {
    /// Inject dictation for this view and everything below it.
    public func transcriber(_ transcriber: any Transcriber) -> some View {
        environment(\.transcriber, transcriber)
    }

    /// Inject photo text reading for this view and everything below it.
    public func textRecognizer(_ recognizer: any TextRecognizer) -> some View {
        environment(\.textRecognizer, recognizer)
    }

    /// Inject permission asking for this view and everything below it.
    public func inputPermissions(_ permissions: any InputPermissions) -> some View {
        environment(\.inputPermissions, permissions)
    }
}

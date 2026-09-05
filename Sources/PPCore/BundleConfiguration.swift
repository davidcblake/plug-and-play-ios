import Foundation

/// Settings that ship inside the app, read from its `Info.plist`.
///
/// This is where build-time values belong. `docs/security.md` rule 1 says no
/// secrets live in the repository: a value that differs per build comes from an
/// encrypted GitHub secret, gets written into `Info.plist` at build time, and
/// is read back through here.
///
/// It is still `Info.plist`, so treat everything in it as readable by anyone
/// holding the app. Fine for an endpoint or a flag. Never for a credential —
/// those belong in the Keychain, per rule 2.
public struct BundleConfiguration: ConfigurationSource {
    private let bundle: Bundle

    /// - Parameter bundle: Defaults to the running app's own bundle. Injectable
    ///   so a test can hand in a bundle it controls.
    public init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    public func value(for key: ConfigurationKey) -> String? {
        guard let raw = bundle.object(forInfoDictionaryKey: key.name) else { return nil }
        // Info.plist values arrive as whatever type the plist declared — string,
        // number, boolean. Normalising to text here keeps the protocol to one
        // simple requirement, and the typed accessors on ConfigurationSource
        // parse it back. `String(describing:)` renders a plist boolean as
        // "true"/"false", which `bool(_:default:)` already understands.
        if let text = raw as? String { return text }
        return String(describing: raw)
    }
}

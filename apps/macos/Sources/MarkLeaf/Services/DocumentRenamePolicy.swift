import Foundation

/// Keeps File → Rename aligned with the read-only guard used by the session.
enum DocumentRenamePolicy {
    static func canRenameActiveDocument(
        hasFileURL: Bool,
        isReadOnly: Bool
    ) -> Bool {
        hasFileURL && !isReadOnly
    }
}

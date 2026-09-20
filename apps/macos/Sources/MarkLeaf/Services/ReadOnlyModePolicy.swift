enum ReadOnlyModeTransition: Equatable {
    case toggle
    case resolveUnsavedChanges
    case blockedFileNotWritable
}

enum ReadOnlyModePolicy {
    static func action(
        currentReadOnly: Bool,
        isDirty: Bool,
        fileURLIsWritable: Bool
    ) -> ReadOnlyModeTransition {
        if !currentReadOnly && isDirty {
            return .resolveUnsavedChanges
        }
        if currentReadOnly && !fileURLIsWritable {
            return .blockedFileNotWritable
        }
        return .toggle
    }
}

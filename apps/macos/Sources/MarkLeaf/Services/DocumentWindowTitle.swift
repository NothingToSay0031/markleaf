import Foundation

enum DocumentWindowTitle {
    struct StatusMarker: Equatable {
        let text: String
        let isVisible: Bool
    }

    static func base(
        fileName: String?,
        untitledLabel: String
    ) -> String {
        fileName?.isEmpty == false ? fileName! : untitledLabel
    }

    static func format(
        fileName: String?,
        isDirty: Bool,
        untitledLabel: String,
        modifiedLabel: String
    ) -> String {
        let baseName = base(fileName: fileName, untitledLabel: untitledLabel)
        return isDirty ? "\(baseName) - \(modifiedLabel)" : baseName
    }

    static func statusMarker(
        isDirty: Bool,
        isReadOnly: Bool,
        modifiedLabel: String,
        readOnlyLabel: String
    ) -> StatusMarker {
        if isReadOnly {
            return StatusMarker(text: readOnlyLabel, isVisible: true)
        }
        if isDirty {
            return StatusMarker(text: modifiedLabel, isVisible: true)
        }
        return StatusMarker(text: modifiedLabel, isVisible: false)
    }
}

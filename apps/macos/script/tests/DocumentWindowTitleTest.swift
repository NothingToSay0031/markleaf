import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

expect(
    DocumentWindowTitle.base(fileName: nil, untitledLabel: "未命名") == "未命名",
    "untitled documents should use the localized base title"
)
expect(
    DocumentWindowTitle.statusMarker(
        isDirty: false,
        isReadOnly: true,
        modifiedLabel: "已修改",
        readOnlyLabel: "只读"
    ) == DocumentWindowTitle.StatusMarker(text: "只读", isVisible: true),
    "read-only documents should show the read-only marker"
)
expect(
    DocumentWindowTitle.statusMarker(
        isDirty: true,
        isReadOnly: false,
        modifiedLabel: "已修改",
        readOnlyLabel: "只读"
    ) == DocumentWindowTitle.StatusMarker(text: "已修改", isVisible: true),
    "modified documents should show the modified marker"
)
expect(
    DocumentWindowTitle.statusMarker(
        isDirty: true,
        isReadOnly: true,
        modifiedLabel: "已修改",
        readOnlyLabel: "只读"
    ) == DocumentWindowTitle.StatusMarker(text: "只读", isVisible: true),
    "read-only status should take priority over modified status"
)
expect(
    DocumentWindowTitle.statusMarker(
        isDirty: false,
        isReadOnly: false,
        modifiedLabel: "已修改",
        readOnlyLabel: "只读"
    ) == DocumentWindowTitle.StatusMarker(text: "已修改", isVisible: false),
    "saved writable documents should hide the status marker"
)
expect(
    DocumentWindowTitle.format(
        fileName: "笔记.md",
        isDirty: false,
        untitledLabel: "未命名",
        modifiedLabel: "已修改"
    ) == "笔记.md",
    "saved documents should keep the plain filename"
)
expect(
    DocumentWindowTitle.format(
        fileName: "笔记.md",
        isDirty: true,
        untitledLabel: "未命名",
        modifiedLabel: "已修改"
    ) == "笔记.md - 已修改",
    "modified documents should append the modified marker"
)
expect(
    DocumentWindowTitle.format(
        fileName: nil,
        isDirty: true,
        untitledLabel: "未命名",
        modifiedLabel: "已修改"
    ) == "未命名 - 已修改",
    "untitled modified documents should still show the marker"
)
print("PASS")

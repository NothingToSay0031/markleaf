import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

expect(
    DocumentRenamePolicy.canRenameActiveDocument(hasFileURL: true, isReadOnly: false),
    "writable local documents can be renamed"
)
expect(
    !DocumentRenamePolicy.canRenameActiveDocument(hasFileURL: true, isReadOnly: true),
    "read-only documents cannot be renamed"
)
expect(
    !DocumentRenamePolicy.canRenameActiveDocument(hasFileURL: false, isReadOnly: false),
    "untitled documents cannot be renamed"
)

print("PASS")

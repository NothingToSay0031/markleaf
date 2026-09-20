import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

expect(NewWindowDocumentPolicy.intent(documentPath: nil) == .blank,
       "a manually created window must start with a blank document")
expect(NewWindowDocumentPolicy.intent(documentPath: "") == .blank,
       "an empty path must not trigger startup document loading")
expect(NewWindowDocumentPolicy.intent(documentPath: "/tmp/note.md") == .open("/tmp/note.md"),
       "an explicit path must remain an open-document intent")

print("PASS")

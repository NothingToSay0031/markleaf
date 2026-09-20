import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

func throwsError<T>(_ expected: T, operation: () throws -> Void) -> Bool where T: Error & Equatable {
    do {
        try operation()
        return false
    } catch let error as T {
        return error == expected
    } catch {
        return false
    }
}

expect(QuickLookDocumentPolicy.maximumBytes == 33_554_432, "the Quick Look limit is exactly 32 MiB")
expect(QuickLookDocumentPolicy.canPreview(extension: "md"), "markdown should preview")
expect(QuickLookDocumentPolicy.canPreview(extension: "MARKDOWN"), "extension checks are case-insensitive")
expect(QuickLookDocumentPolicy.canPreview(extension: "txt"), "plain text should preview")
expect(!QuickLookDocumentPolicy.canPreview(extension: "html"), "HTML must not preview")

try QuickLookDocumentPolicy.validate(
    size: QuickLookDocumentPolicy.maximumBytes,
    pathExtension: "md",
    contentType: nil
)
expect(throwsError(QuickLookDocumentError.tooLarge, operation: {
    try QuickLookDocumentPolicy.validate(
        size: QuickLookDocumentPolicy.maximumBytes + 1,
        pathExtension: "md",
        contentType: nil
    )
}), "oversize files are rejected")
expect(throwsError(QuickLookDocumentError.unsupportedType, operation: {
    try QuickLookDocumentPolicy.validate(size: 1, pathExtension: "pdf", contentType: "com.adobe.pdf")
}), "unsupported files are rejected")
expect(QuickLookDocumentPolicy.canPreview(contentType: "net.daringfireball.markdown"), "markdown UTI should preview")
expect(QuickLookDocumentPolicy.canPreview(contentType: "public.plain-text"), "plain text UTI should preview")

expect(QuickLookDocumentPolicy.decode(Data("# 中文".utf8)) == "# 中文", "UTF-8 is preserved")
let utf16 = Data([0xFF, 0xFE]) + (Data("中文".data(using: .utf16LittleEndian) ?? Data()))
expect(QuickLookDocumentPolicy.decode(utf16).contains("中文"), "UTF-16 decodes safely")
expect(!QuickLookDocumentPolicy.decode(Data([0xD8, 0x00])).isEmpty, "invalid bytes do not crash")
print("PASS")

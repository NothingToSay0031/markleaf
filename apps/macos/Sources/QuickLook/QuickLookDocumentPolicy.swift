import Foundation

enum QuickLookDocumentError: Error, Equatable {
    case unsupportedType
    case tooLarge
    case unreadable
}

struct QuickLookDocumentPolicy {
    static let maximumBytes = 32 * 1024 * 1024
    private static let extensions: Set<String> = ["md", "markdown", "txt"]
    private static let contentTypes: Set<String> = [
        "net.daringfireball.markdown",
        "public.plain-text",
    ]

    static func canPreview(extension pathExtension: String) -> Bool {
        extensions.contains(pathExtension.lowercased())
    }

    static func canPreview(contentType identifier: String) -> Bool {
        contentTypes.contains(identifier)
    }

    static func validate(size: Int, pathExtension: String, contentType: String?) throws {
        let typeMatches = contentType.map(canPreview(contentType:)) ?? false
        guard typeMatches || canPreview(extension: pathExtension) else {
            throw QuickLookDocumentError.unsupportedType
        }
        guard size >= 0, size <= maximumBytes else {
            throw QuickLookDocumentError.tooLarge
        }
    }

    static func decode(_ data: Data) -> String {
        let encodings: [String.Encoding] = [
            .utf8,
            .utf16,
            .utf16BigEndian,
            .utf16LittleEndian,
            .windowsCP1252,
            .isoLatin1,
            .macOSRoman,
        ]
        for encoding in encodings {
            if let text = String(data: data, encoding: encoding) {
                return text.hasPrefix("\u{FEFF}") ? String(text.dropFirst()) : text
            }
        }
        return String(decoding: data, as: UTF8.self)
    }
}

import Foundation

/// Common fenced-code language identifiers offered by the native picker.
/// The picker remains editable, so this list is a convenience rather than a
/// validation allowlist.
enum CodeBlockLanguageCatalog {
    static let commonLanguages = [
        "swift",
        "c",
        "cpp",
        "objective-c",
        "java",
        "kotlin",
        "python",
        "javascript",
        "typescript",
        "jsx",
        "tsx",
        "html",
        "css",
        "json",
        "yaml",
        "xml",
        "shell",
        "powershell",
        "sql",
        "markdown",
        "verilog",
        "latex",
        "go",
        "rust",
        "php",
        "ruby",
        "r",
        "toml",
        "ini",
        "diff",
        "mermaid",
    ]

    static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func displayRank(forLanguage language: String) -> Int? {
        commonLanguages.firstIndex(of: language)
    }

    static func sortedForDisplay(_ languages: [String]) -> [String] {
        let known = languages.filter { displayRank(forLanguage: $0) != nil }
        let unknown = languages.filter { displayRank(forLanguage: $0) == nil }
        return known.sorted { lhs, rhs in
            (displayRank(forLanguage: lhs) ?? .max) < (displayRank(forLanguage: rhs) ?? .max)
        } + unknown
    }

    static func formatterDisplayRank(forLanguages languages: [String]) -> Int {
        languages.compactMap { displayRank(forLanguage: $0) }.min() ?? commonLanguages.count
    }
}

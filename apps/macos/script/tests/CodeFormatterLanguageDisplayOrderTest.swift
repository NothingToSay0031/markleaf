import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

let expectedToolOrder = [
    "clang-format",
    "google-java-format",
    "black",
    "xmllint",
    "shfmt",
    "sqlfluff",
    "verible-verilog-format",
    "latexindent",
    "gofmt",
    "rustfmt",
    "taplo",
]
expect(
    ExternalCodeFormatterCatalog.displayTools.map(\.id) == expectedToolOrder,
    "formatter manager order should follow the declared language catalog"
)

let clangLanguages = ExternalCodeFormatterCatalog.tools.first { $0.id == "clang-format" }!.languages
expect(
    clangLanguages.prefix(3) == ["c", "cpp", "objective-c"],
    "aliases should follow declared languages before implementation aliases"
)

print("Code formatter display order tests passed")

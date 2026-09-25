import Foundation

func expect(_ condition: Bool, _ message: String) {
    guard condition else {
        fatalError("FAIL: \(message)")
    }
}

let fileManager = FileManager.default
let root = fileManager.temporaryDirectory
    .appendingPathComponent("markleaf-formatter-launch-\(UUID().uuidString)")
let javaDirectory = root.appendingPathComponent("bin")
try fileManager.createDirectory(at: javaDirectory, withIntermediateDirectories: true)

let javaPath = javaDirectory.appendingPathComponent("java").path
fileManager.createFile(
    atPath: javaPath,
    contents: Data("#!/bin/sh\n".utf8)
)
try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: javaPath)

let jarPath = root.appendingPathComponent("google-java-format.jar").path
fileManager.createFile(atPath: jarPath, contents: Data())

let tool = ExternalCodeFormatterCatalog.tools.first { $0.id == "google-java-format" }
expect(tool != nil, "google-java-format tool should exist")
let languageTools: [String: String] = [
    "rust": "rustfmt",
    "go": "gofmt",
    "sql": "sqlfluff",
    "shell": "shfmt",
    "toml": "taplo",
    "xml": "xmllint",
]
for (language, expectedToolID) in languageTools {
    let languageTool = ExternalCodeFormatterCatalog.tool(language: language)
    expect(languageTool?.id == expectedToolID, "\(language) should map to \(expectedToolID)")
}
expect(
    ExternalCodeFormatterCatalog.tool(language: "objective-c")?.id == "clang-format",
    "Objective-C should reuse clang-format"
)
expect(tool?.selectionLineRangePrefix == "--lines=", "google-java-format should support line ranges")
expect(
    ExternalCodeFormatterCatalog.processArguments(for: tool!, selectionLineRange: 2...2) == ["--lines=2:2", "-"],
    "Java selection should pass a one-based line range"
)
expect(
    ExternalCodeFormatterCatalog.processArguments(for: tool!, selectionLineRange: nil) == ["-"],
    "whole-block Java formatting should not pass a line range"
)
let jarLaunch = ExternalCodeFormatterLaunch(
    executablePath: javaPath,
    arguments: ["-jar", jarPath, "-"],
    environment: [:]
)
expect(
    ExternalCodeFormatterCatalog.processArguments(
        for: tool!,
        launch: jarLaunch,
        selectionLineRange: nil
    ) == ["-jar", jarPath, "-"],
    "Java process arguments must retain the JAR launcher prefix"
)
expect(
    ExternalCodeFormatterCatalog.processArguments(
        for: tool!,
        launch: jarLaunch,
        selectionLineRange: 2...2
    ) == ["-jar", jarPath, "--lines=2:2", "-"],
    "Java process arguments must retain the JAR launcher prefix for selections"
)
expect(
    ExternalCodeFormatterCatalog.processArguments(
        for: ExternalCodeFormatterCatalog.tool(language: "rust")!,
        selectionLineRange: nil
    ) == ["--emit", "stdout"],
    "rustfmt should write formatted output to stdout"
)
expect(
    ExternalCodeFormatterCatalog.processArguments(
        for: ExternalCodeFormatterCatalog.tool(language: "sql")!,
        selectionLineRange: nil
    ) == ["format", "--dialect", "ansi", "-"],
    "sqlfluff should use its format subcommand"
)

let configuredPaths = ["google-java-format": jarPath]
let javaAvailability = ExternalCodeFormatterCatalog.availability(
    for: tool!,
    configuredPaths: configuredPaths,
    environment: ["PATH": javaDirectory.path],
    javaRuntimeLookup: .candidates([javaPath])
)
guard case .available(let javaLaunch) = javaAvailability else {
    fatalError("FAIL: configured JAR formatter with Java should be available")
}
expect(javaLaunch.executablePath == javaPath, "JAR formatter should launch through java")
expect(javaLaunch.arguments == ["-jar", jarPath, "-"], "JAR launch should pass -jar and formatter arguments")
expect(javaLaunch.environment["HOME"] == NSHomeDirectory(), "formatter processes should retain the GUI environment base")

let languages = ExternalCodeFormatterCatalog.availableLanguages(
    configuredPaths: configuredPaths,
    environment: ["PATH": javaDirectory.path]
)
expect(languages.contains("java"), "configured JAR formatter should enable Java")

let missingJavaLanguages = ExternalCodeFormatterCatalog.availableLanguages(
    configuredPaths: configuredPaths,
    environment: ["PATH": "/nonexistent-markleaf-formatter-bin"],
    javaRuntimeLookup: .candidates([])
)
expect(!missingJavaLanguages.contains("java"), "JAR formatter should require Java")
let missingJavaAvailability = ExternalCodeFormatterCatalog.availability(
    for: tool!,
    configuredPaths: configuredPaths,
    environment: ["PATH": "/nonexistent-markleaf-formatter-bin"],
    javaRuntimeLookup: .candidates([])
)
guard case .jarMissingJavaRuntime = missingJavaAvailability else {
    fatalError("FAIL: configured JAR without Java should report the missing runtime")
}

let invalidAssetPath = root.appendingPathComponent("not-executable.txt").path
fileManager.createFile(atPath: invalidAssetPath, contents: Data())
let invalidAvailability = ExternalCodeFormatterCatalog.availability(
    for: tool!,
    configuredPaths: ["google-java-format": invalidAssetPath],
    environment: ["PATH": javaDirectory.path],
    javaRuntimeLookup: .candidates([javaPath])
)
guard case .invalidCustomPath = invalidAvailability else {
    fatalError("FAIL: non-executable custom formatter should report an invalid custom path")
}

let nativeFormatterPath = javaDirectory.appendingPathComponent("google-java-format").path
fileManager.createFile(atPath: nativeFormatterPath, contents: Data("#!/bin/sh\n".utf8))
try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: nativeFormatterPath)
let nativeLaunch = ExternalCodeFormatterCatalog.launch(
    for: tool!,
    configuredPaths: [:],
    environment: ["PATH": javaDirectory.path]
)
expect(nativeLaunch?.executablePath == nativeFormatterPath, "native formatter should launch directly")
expect(nativeLaunch?.arguments == ["-"], "native formatter should keep its own arguments")

let latexTool = ExternalCodeFormatterCatalog.tools.first { $0.id == "latexindent" }
expect(latexTool != nil, "latexindent tool should exist")
let latexPath = javaDirectory.appendingPathComponent("latexindent").path
fileManager.createFile(atPath: latexPath, contents: Data("#!/bin/sh\n".utf8))
try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: latexPath)
let latexLaunch = ExternalCodeFormatterCatalog.launch(
    for: latexTool!,
    configuredPaths: [:],
    environment: ["PATH": javaDirectory.path]
)
expect(latexLaunch?.environment["PERL5LIB"]?.contains(NSHomeDirectory() + "/perl5/lib/perl5") == true, "latexindent should receive local CPAN search paths")
let latexPresentAvailability = ExternalCodeFormatterCatalog.availability(
    for: latexTool!,
    configuredPaths: [:],
    environment: ["PATH": javaDirectory.path],
    perlModuleLookup: .present
)
guard case .available = latexPresentAvailability else {
    fatalError("FAIL: latexindent with File::HomeDir should be available")
}
let latexMissingAvailability = ExternalCodeFormatterCatalog.availability(
    for: latexTool!,
    configuredPaths: [:],
    environment: ["PATH": javaDirectory.path],
    perlModuleLookup: .missing
)
guard case .latexMissingPerlRuntime = latexMissingAvailability else {
    fatalError("FAIL: latexindent without File::HomeDir should report the missing Perl runtime")
}
let missingPerlLanguages = ExternalCodeFormatterCatalog.availableLanguages(
    configuredPaths: [:],
    environment: ["PATH": javaDirectory.path],
    perlModuleLookup: .missing
)
expect(!missingPerlLanguages.contains("latex"), "missing File::HomeDir should disable LaTeX")
expect(!missingPerlLanguages.contains("tex"), "missing File::HomeDir should disable TeX")

let javaDownloadURL = ExternalCodeFormatterCatalog.javaRuntimeDownloadURL
expect(javaDownloadURL.host == "adoptium.net", "Java runtime guidance should use Adoptium")
expect(javaDownloadURL.path.contains("/temurin/releases"), "Java runtime guidance should point to Temurin releases")

// GUI apps do not inherit shell PATH entries such as /opt/homebrew/bin.
// Exercise the fallback with the same minimal launchd PATH; when Verible is
// installed in a common location it must still be detected.
let veribleTool = ExternalCodeFormatterCatalog.tools.first { $0.id == "verible-verilog-format" }
expect(veribleTool != nil, "Verible formatter should be cataloged")
let veribleFallbackPath = "/opt/homebrew/bin/verible-verilog-format"
if fileManager.isExecutableFile(atPath: veribleFallbackPath) {
    let veribleAvailability = ExternalCodeFormatterCatalog.availability(
        for: veribleTool!,
        configuredPaths: [:],
        environment: ["PATH": "/usr/bin:/bin:/usr/sbin:/sbin"]
    )
    guard case .available(let veribleLaunch) = veribleAvailability else {
        fatalError("FAIL: Homebrew Verible should be found without a shell PATH")
    }
    expect(veribleLaunch.executablePath == veribleFallbackPath, "Verible fallback should preserve the resolved executable")
}

print("ExternalCodeFormatterLaunch tests passed")

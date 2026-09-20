// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MarkLeaf",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "MarkLeaf",
            path: "Sources/MarkLeaf"
        ),
        .executableTarget(
            name: "MarkLeafQuickLook",
            path: "Sources/QuickLook",
            exclude: ["entitlements.plist"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("QuickLookUI"),
                .linkedFramework("WebKit"),
                .unsafeFlags(["-Xlinker", "-e", "-Xlinker", "_NSExtensionMain"]),
            ]
        )
    ]
)

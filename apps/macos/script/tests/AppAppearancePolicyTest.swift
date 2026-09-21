import AppKit

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

expect(AppAppearancePolicy.appearanceName(themeIsDark: true, followsSystem: true) == nil,
       "system sync must inherit macOS appearance")
expect(AppAppearancePolicy.appearanceName(themeIsDark: false, followsSystem: true) == nil,
       "system sync must inherit macOS appearance")
expect(AppAppearancePolicy.appearanceName(themeIsDark: true, followsSystem: false) == .darkAqua,
       "manual dark theme must override the system appearance")
expect(AppAppearancePolicy.appearanceName(themeIsDark: false, followsSystem: false) == .aqua,
       "manual light theme must override a dark system")

print("PASS")

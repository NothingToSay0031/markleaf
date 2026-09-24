import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

expect(RecoveryOpenPolicy.buttonTitle == "打开", "the recovery action should be named Open")
expect(RecoveryOpenPolicy.canOpen(isSelected: true), "Open should be available for a selected snapshot")
expect(!RecoveryOpenPolicy.canOpen(isSelected: false), "Open should not run without a selection")
expect(
    RecoveryOpenPolicy.destination(hasActiveWindow: true, multiTabEnabled: true) == .currentTab,
    "Open should reuse the active window when tabs are enabled"
)
expect(
    RecoveryOpenPolicy.destination(hasActiveWindow: true, multiTabEnabled: false) == .newWindow,
    "Open should avoid replacing a document when tabs are disabled"
)
expect(
    RecoveryOpenPolicy.destination(hasActiveWindow: false, multiTabEnabled: true) == .newWindow,
    "Open should create a window when no editor window is active"
)

print("RecoveryOpenPolicy tests passed")

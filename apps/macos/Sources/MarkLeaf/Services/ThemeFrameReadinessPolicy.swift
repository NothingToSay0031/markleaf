import CoreGraphics
import Foundation
import AppKit

/// WKWebView 的 `afterScreenUpdates` 回调仍可能返回样式注入前的白色旧帧；
/// 只有抽样像素达到主题底色时，才允许移除加载遮罩。
enum ThemeFrameReadinessPolicy {
    /// WKWebView snapshots can pass colors through the display profile. Keep the
    /// check tight enough to reject white/stale pages, but tolerant of the small
    /// drift produced around dark theme backgrounds.
    static let tolerance: CGFloat = 0.05
    static let timeout: TimeInterval = 1.0

    static func isReady(pixel: NSColor, target: NSColor) -> Bool {
        guard let sample = pixel.usingColorSpace(.sRGB),
              let expected = target.usingColorSpace(.sRGB) else { return false }
        // The editor WebView intentionally disables its own background. Fully
        // transparent snapshot pixels therefore expose the themed native backing
        // (not a stale white page) and are safe to reveal immediately.
        if sample.alphaComponent <= 0.02 { return true }
        guard sample.alphaComponent > 0.98 else { return false }

        let differences = [
            abs(sample.redComponent - expected.redComponent),
            abs(sample.greenComponent - expected.greenComponent),
            abs(sample.blueComponent - expected.blueComponent),
        ]
        return differences.allSatisfy { $0 <= tolerance }
    }

    /// WebKit can commit stale and prepared regions in the same frame. Margin
    /// samples cover the whole viewport while avoiding prose text; three hits
    /// are enough to accept a blank-background frame without requiring every
    /// sample to dodge inline content.
    static func isReady(pixels: [NSColor?], target: NSColor) -> Bool {
        let matchingCount = pixels
            .compactMap { $0 }
            .filter { isReady(pixel: $0, target: target) }
            .count
        return matchingCount >= min(3, pixels.count)
    }

    static func shouldContinueWaiting(
        didCapture: Bool,
        pixel: NSColor?,
        target: NSColor,
        elapsed: TimeInterval,
        timeout: TimeInterval = 1.0
    ) -> Bool {
        if let pixel, isReady(pixel: pixel, target: target) { return false }
        return elapsed < timeout
    }

    static func shouldContinueWaiting(
        didCapture: Bool,
        pixels: [NSColor?],
        target: NSColor,
        elapsed: TimeInterval,
        matchingStableCount: Int,
        requiredStableCount: Int = 2,
        timeout: TimeInterval = 1.0
    ) -> Bool {
        guard didCapture, isReady(pixels: pixels, target: target) else {
            return elapsed < timeout
        }
        return matchingStableCount < requiredStableCount
    }
}

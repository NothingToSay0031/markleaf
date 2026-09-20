import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

let markdown = [
    "# 标题",
    "",
    "Plain <script>alert(1)</script> and **bold** and `code`.",
    "",
    "- [x] done",
    "- [ ] todo",
    "",
    "> quote",
    "",
    "```swift",
    "let x = 1",
    "```",
    "",
    "| Name | Count |",
    "| --- | ---: |",
    "| Apples | 3 |",
    "",
    "![Figure](figure.png)",
    "![Bad](../../secret.png)",
    "",
"Inline $x^2$ formula.",
"Alpha $\\alpha_1 \\times \\beta^{2n}$ formula.",
].joined(separator: "\n")

let html = QuickLookHTMLRenderer.document(
    title: "Sample",
    markdown: markdown,
    isPlainText: false
)

expect(html.contains("<h1>标题</h1>"), "ATX headings render")
expect(html.contains("&lt;script&gt;"), "raw HTML is escaped")
expect(html.contains("<strong>bold</strong>"), "bold renders")
expect(html.contains("<code>code</code>"), "inline code renders")
expect(html.contains("task-item"), "task lists render")
expect(html.contains("<blockquote>"), "quotes render")
expect(html.contains("<pre><code class=\"language-swift\">"), "fenced code preserves language")
expect(html.contains("<table>"), "tables render")
expect(html.contains("<span class=\"image-fallback\">Figure</span>"), "local images keep alt text")
expect(html.contains("<span class=\"image-fallback\">Bad</span>"), "unavailable images keep alt text")
expect(!html.contains("secret.png"), "traversal target never reaches HTML")
expect(html.contains("Inline <span class=\"math-inline\">x<sup>2</sup></span> formula."), "inline formulas render superscripts")
expect(!html.contains("$x^2$"), "inline formulas do not expose raw delimiters")
expect(html.contains("<span class=\"math-inline\">α<sub>1</sub> × β<sup>2n</sup></span>"), "inline formulas render common symbols and subscripts")
expect(html.contains("script-src 'none'"), "CSP disables scripts")

let plain = QuickLookHTMLRenderer.document(
    title: "Text",
    markdown: "<script>alert(1)</script>",
    isPlainText: true
)
expect(plain.contains("<pre class=\"plain-text\">"), "plain text uses a preformatted document")
expect(plain.contains("&lt;script&gt;"), "plain text escapes HTML")

expect(QuickLookHTMLRenderer.errorPage("too large").contains("too large"), "error pages preserve the reason")
expect(QuickLookHTMLRenderer.errorPage("too large").contains("script-src 'none'"), "error pages disable scripts")
expect(QuickLookHTMLRenderer.errorPage("too large").contains("script-src 'none'"), "error pages use the secure CSP")
print("PASS")

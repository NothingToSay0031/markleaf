import Foundation
import AppKit
import QuickLookUI
import UniformTypeIdentifiers

@objc(PreviewViewController)
final class PreviewViewController: QLPreviewProvider, QLPreviewingController {
    func providePreview(
        for request: QLFilePreviewRequest,
        completionHandler: @escaping (QLPreviewReply?, Error?) -> Void
    ) {
        let url = request.fileURL
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let size = (attributes[.size] as? NSNumber)?.intValue ?? -1
            let contentType = (try? url.resourceValues(forKeys: [.contentTypeKey]))?.contentType?.identifier
            try QuickLookDocumentPolicy.validate(
                size: size,
                pathExtension: url.pathExtension,
                contentType: contentType
            )
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let markdown = QuickLookDocumentPolicy.decode(data)
            let html = QuickLookHTMLRenderer.document(
                title: url.deletingPathExtension().lastPathComponent,
                markdown: markdown,
                isPlainText: url.pathExtension.lowercased() == "txt"
            )

            let reply = QLPreviewReply(
                dataOfContentType: .html,
                contentSize: QuickLookPreviewLayout.contentSize(
                    visible: NSScreen.main?.visibleFrame.size
                )
            ) { reply in
                return Data(html.utf8)
            }
            reply.title = url.deletingPathExtension().lastPathComponent
            completionHandler(reply, nil)
        } catch {
            let reply = QLPreviewReply(
                dataOfContentType: .html,
                contentSize: QuickLookPreviewLayout.contentSize(
                    visible: NSScreen.main?.visibleFrame.size
                )
            ) { _ in
                Data(QuickLookHTMLRenderer.errorPage(failureMessage(for: error)).utf8)
            }
            completionHandler(reply, nil)
        }
    }
}

private func failureMessage(for error: Error) -> String {
    if let documentError = error as? QuickLookDocumentError {
        switch documentError {
        case .tooLarge:
            return "文件超过 32 MiB，无法预览。"
        case .unsupportedType:
            return "此文件类型不支持 Quick Look 预览。"
        case .unreadable:
            return "文件无法读取。"
        }
    }
    return "文件无法读取。"
}

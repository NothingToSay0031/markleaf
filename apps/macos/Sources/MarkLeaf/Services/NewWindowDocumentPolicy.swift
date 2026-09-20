import Foundation

enum NewWindowDocumentIntent: Equatable {
    case blank
    case open(String)
}

enum NewWindowDocumentPolicy {
    static func intent(documentPath: String?) -> NewWindowDocumentIntent {
        guard let documentPath, !documentPath.isEmpty else { return .blank }
        return .open(documentPath)
    }
}

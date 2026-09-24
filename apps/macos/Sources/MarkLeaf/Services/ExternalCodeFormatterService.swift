import Foundation

struct ExternalCodeFormatterRequest: Equatable {
    let code: String
    let language: String
    let selectionLineRange: ClosedRange<Int>?
}

enum ExternalCodeFormatterOutcome {
    case formatted(String)
    case unchanged
    case failed(String)
}

final class ExternalCodeFormatterService {
    static let shared = ExternalCodeFormatterService()

    private let queue = DispatchQueue(label: "com.markleaf.external-code-formatter", qos: .userInitiated)

    func format(
        _ request: ExternalCodeFormatterRequest,
        settings: AppSettings = SettingsService.shared.settings,
        completion: @escaping (ExternalCodeFormatterOutcome) -> Void
    ) {
        guard let tool = ExternalCodeFormatterCatalog.tool(language: request.language) else {
            completion(.failed("unsupported language"))
            return
        }
        let availability = ExternalCodeFormatterCatalog.availability(
            for: tool,
            configuredPaths: settings.codeFormatterPaths
        )
        guard case .available(let launch) = availability else {
            let message: String
            switch availability {
            case .jarMissingJavaRuntime:
                message = L10n.t("Java 运行时不可用，无法格式化 Java 代码。")
            case .latexMissingPerlRuntime:
                message = L10n.t("缺少 Perl 模块 File::HomeDir，无法格式化 LaTeX 代码。")
            case .invalidCustomPath:
                message = L10n.t("自定义路径无效")
            case .notInstalled:
                message = "formatter not installed: \(tool.displayName)"
            case .available:
                message = "formatter unavailable"
            }
            completion(.failed(message))
            return
        }

        queue.async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: launch.executablePath)
            process.arguments = ExternalCodeFormatterCatalog.processArguments(
                for: tool,
                launch: launch,
                selectionLineRange: request.selectionLineRange,
                sqlDialect: settings.sqlFormatterDialect
            )
            process.environment = launch.environment

            let input = Pipe()
            let output = Pipe()
            let error = Pipe()
            process.standardInput = input
            process.standardOutput = output
            process.standardError = error

            do {
                try process.run()
            } catch {
                completion(.failed(error.localizedDescription))
                return
            }

            let group = DispatchGroup()
            group.enter()
            DispatchQueue.global().async {
                defer { try? input.fileHandleForWriting.close() }
                let data = Data(request.code.utf8)
                var offset = 0
                while offset < data.count {
                    let chunk = data.subdata(in: offset..<min(offset + 1024 * 1024, data.count))
                    input.fileHandleForWriting.write(chunk)
                    offset += chunk.count
                }
                group.leave()
            }

            group.enter()
            let outputData = output.fileHandleForReading.readDataToEndOfFile()
            group.leave()
            group.enter()
            let errorData = error.fileHandleForReading.readDataToEndOfFile()
            group.leave()
            group.wait()
            process.waitUntilExit()

            guard process.terminationStatus == 0, let formatted = String(data: outputData, encoding: .utf8) else {
                let message = String(data: errorData, encoding: .utf8) ?? "formatter exited with \(process.terminationStatus)"
                let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
                let lowercasedMessage = trimmedMessage.lowercased()
                if lowercasedMessage.contains("no java runtime") || lowercasedMessage.contains("java runtime could not be located") {
                    completion(.failed(L10n.t("Java 运行时不可用，无法格式化 Java 代码。")))
                } else if lowercasedMessage.contains("can't locate file/homedir.pm") {
                    completion(.failed(L10n.t("缺少 Perl 模块 File::HomeDir，无法格式化 LaTeX 代码。")))
                } else {
                    completion(.failed(trimmedMessage))
                }
                return
            }
            if formatted == request.code {
                completion(.unchanged)
            } else {
                completion(.formatted(formatted))
            }
        }
    }
}

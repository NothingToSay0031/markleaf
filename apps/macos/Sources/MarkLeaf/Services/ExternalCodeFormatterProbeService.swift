import Foundation

struct ExternalCodeFormatterProbeResult: Equatable {
    let id: String
    let displayName: String
    let isSuccess: Bool
    let detail: String
}

final class ExternalCodeFormatterProbeService {
    static let shared = ExternalCodeFormatterProbeService()

    private let queue = DispatchQueue(label: "com.markleaf.external-code-formatter-probe", qos: .userInitiated)

    func probe(
        settings: AppSettings = SettingsService.shared.settings,
        completion: @escaping ([ExternalCodeFormatterProbeResult]) -> Void
    ) {
        queue.async { [tools = ExternalCodeFormatterCatalog.tools] in
            var results: [ExternalCodeFormatterProbeResult] = []
            for tool in tools {
                results.append(self.probe(tool: tool, settings: settings))
            }
            DispatchQueue.main.async {
                completion(results)
            }
        }
    }

    func probe(
        tool: ExternalCodeFormatterTool,
        settings: AppSettings = SettingsService.shared.settings,
        completion: @escaping (ExternalCodeFormatterProbeResult) -> Void
    ) {
        queue.async {
            let result = self.probe(tool: tool, settings: settings)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    private func probe(tool: ExternalCodeFormatterTool, settings: AppSettings) -> ExternalCodeFormatterProbeResult {
        let availability = ExternalCodeFormatterCatalog.availability(
            for: tool,
            configuredPaths: settings.codeFormatterPaths
        )
        guard case .available(let launch) = availability else {
            return ExternalCodeFormatterProbeResult(
                id: tool.id,
                displayName: tool.displayName,
                isSuccess: false,
                detail: availabilityDetail(availability, tool: tool)
            )
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: launch.executablePath)
        process.arguments = ExternalCodeFormatterCatalog.processArguments(
            for: tool,
            launch: launch,
            probeArguments: ExternalCodeFormatterCatalog.probeArguments(for: tool)
        )
        process.environment = launch.environment
        process.standardInput = FileHandle.nullDevice

        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error

        do {
            try process.run()
        } catch {
            return ExternalCodeFormatterProbeResult(
                id: tool.id,
                displayName: tool.displayName,
                isSuccess: false,
                detail: error.localizedDescription
            )
        }

        let outputData = output.fileHandleForReading.readDataToEndOfFile()
        let errorData = error.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let outputText = summary(from: outputData)
        let errorText = summary(from: errorData)
        let detail = outputText.isEmpty ? errorText : outputText
        let isSuccess = process.terminationStatus == 0
        return ExternalCodeFormatterProbeResult(
            id: tool.id,
            displayName: tool.displayName,
            isSuccess: isSuccess,
            detail: detail.isEmpty ? launch.executablePath : detail
        )
    }

    private func availabilityDetail(
        _ availability: ExternalCodeFormatterAvailability,
        tool: ExternalCodeFormatterTool
    ) -> String {
        switch availability {
        case .jarMissingJavaRuntime:
            return L10n.t("缺少 Java 运行时")
        case .latexMissingPerlRuntime:
            return L10n.t("缺少 Perl 模块 File::HomeDir")
        case .invalidCustomPath:
            return L10n.t("自定义路径无效")
        case .notInstalled:
            return L10n.t("未安装")
        case .available:
            return L10n.t("不可用")
        }
    }

    private func summary(from data: Data) -> String {
        let text = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text
            .split(separator: "\n")
            .prefix(1)
            .joined(separator: "\n")
    }
}

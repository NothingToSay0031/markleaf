import Foundation

enum SQLFormatterDialect: String, Codable, CaseIterable {
    case ansi
    case postgres
    case mysql
    case sqlite
    case bigquery
    case tsql = "tsql"

    static func normalized(_ rawValue: String) -> SQLFormatterDialect {
        switch rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "postgresql", "postgre", "pg":
            return .postgres
        case "ts-sql", "mssql":
            return .tsql
        default:
            return SQLFormatterDialect(rawValue: rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) ?? .ansi
        }
    }

    var displayName: String {
        switch self {
        case .ansi: return "ANSI"
        case .postgres: return "PostgreSQL"
        case .mysql: return "MySQL"
        case .sqlite: return "SQLite"
        case .bigquery: return "BigQuery"
        case .tsql: return "T-SQL"
        }
    }
}

import SwiftSyntax
import SwiftDiagnostics

extension DiagnosticsError {
    
    static func from(
        _ message: some DiagnosticMessage,
        node: some SyntaxProtocol
    ) -> Self {
        return .init(diagnostics: [.init(node: node, message: message)])
    }
}

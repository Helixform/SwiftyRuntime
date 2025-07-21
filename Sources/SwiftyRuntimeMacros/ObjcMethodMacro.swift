import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

/// Common requirements for `ObjcMethodMacro` and `ObjcClassMethodMacro`.
protocol ObjcMethodMacroImplementing: ExpressionMacro {
    
    static var forClassMethod: Bool { get }
}

extension ObjcMethodMacroImplementing {
    
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        // Gather macro arguments.
        let arguments = node.arguments
        var argumentIterator = arguments.makeIterator()
        
        let selectorExpr = try requireNextArgument(&argumentIterator, arguments: arguments).expression
        let clsExpr = try requireNextArgument(&argumentIterator, arguments: arguments).expression
        let typeExpr = try requireNextArgument(&argumentIterator, arguments: arguments).expression
        
        let (methodArgumentTypes, methodReturnType) = try resolveMethodType(with: typeExpr)
        
        // Construct auxiliary syntax elements.
        let selectorVarIdentifier = context.makeUniqueName("SelectorVariable")
        let methodVarIdentifier = context.makeUniqueName("MethodVariable")
        let impVarIdentifier = context.makeUniqueName("ImpVariable")
        let typedImpVarIdentifier = context.makeUniqueName("TypedImpVariable")
        
        let selectorVariableDecl: ExprSyntax = "let \(selectorVarIdentifier) = NSSelectorFromString(\(selectorExpr))"
        let getMethodExpr: ExprSyntax = if forClassMethod {
            "class_getClassMethod(\(clsExpr), \(selectorVarIdentifier))"
        } else {
            "class_getInstanceMethod(\(clsExpr), \(selectorVarIdentifier))"
        }
        let invokerArgumentsExpr = TupleExprSyntax(elements: .init {
            methodArgumentTypes.map { .init(expression: $0) }
        })
        let impArgumentsExpr = TupleExprSyntax(elements: .init {
            LabeledExprSyntax(expression: "AnyObject" as ExprSyntax)
            LabeledExprSyntax(expression: "Selector" as ExprSyntax)
            methodArgumentTypes.map { .init(expression: $0) }
        })
        let invokerClosureArguments = methodArgumentTypes.enumerated().map {
            ", $\($0.offset)"
        }.joined()
        
        // Construct final expression.
        let commonCode: ExprSyntax = """
        \(selectorVariableDecl)
        guard let \(methodVarIdentifier) = \(getMethodExpr) else {
            return nil
        }
        let \(impVarIdentifier) = method_getImplementation(\(methodVarIdentifier))
        let \(typedImpVarIdentifier) = unsafeBitCast(
            \(impVarIdentifier),
            to: (@convention(c) \(impArgumentsExpr) -> \(methodReturnType)).self
        )
        """
        
        return if forClassMethod {
            """
            { () -> (\(invokerArgumentsExpr) -> \(methodReturnType))? in
                \(commonCode)
                return {
                    return \(typedImpVarIdentifier)(\(clsExpr), \(selectorVarIdentifier)\(raw: invokerClosureArguments))
                }
            }()
            """
        } else {
            """
            { () -> ((AnyObject) -> (\(invokerArgumentsExpr) -> \(methodReturnType)))? in
                \(commonCode)
                return { target in
                    return {
                        return \(typedImpVarIdentifier)(target, \(selectorVarIdentifier)\(raw: invokerClosureArguments))
                    }
                }
            }()
            """
        }
    }
    
    private static func requireNextArgument<I>(
        _ iterator: inout I,
        arguments: some SyntaxProtocol
    ) throws -> I.Element where I: IteratorProtocol, I.Element: SyntaxProtocol {
        guard let syntax = iterator.next() else {
            throw DiagnosticsError.from(
                ObjcMethodMacroDiagnostic(message: "Missing required arguments", id: .missingArgument),
                node: arguments
            )
        }
        return syntax
    }
    
    private static func resolveMethodType(with typeExpr: ExprSyntax) throws -> ([ExprSyntax], ExprSyntax) {
        guard let memberAccessExpr = typeExpr.as(MemberAccessExprSyntax.self),
              memberAccessExpr.declName.baseName.text == "self",
              let base = memberAccessExpr.base?.as(TupleExprSyntax.self),
              let closureTypeExpr = base.elements.first?.expression.as(InfixOperatorExprSyntax.self),
              closureTypeExpr.operator.as(ArrowExprSyntax.self) != nil,
              let argumentList = closureTypeExpr.leftOperand.as(TupleExprSyntax.self)?.elements.map({ $0.expression }) else {
            throw DiagnosticsError.from(
                ObjcMethodMacroDiagnostic(message: "'type' must be a closure type", id: .mustBeClosureType),
                node: typeExpr
            )
        }
        
        return (argumentList, closureTypeExpr.rightOperand)
    }
}

/// Macro implementation for `#objcMethod`.
struct ObjcMethodMacro: ObjcMethodMacroImplementing {
    
    static let forClassMethod: Bool = false
}

/// Macro implementation for `#objcClassMethod`.
struct ObjcClassMethodMacro: ObjcMethodMacroImplementing {
    
    static let forClassMethod: Bool = true
}

struct ObjcMethodMacroDiagnostic: DiagnosticMessage {
    
    enum ID: String {
        case missingArgument = "missing argument"
        case mustBeClosureType = "must be closure type"
    }

    var message: String
    var diagnosticID: MessageID
    var severity: DiagnosticSeverity = .error
    
    init(message: String, id: ID) {
        self.message = message
        self.diagnosticID = MessageID(domain: "SwiftyRuntime", id: "ObjcMethodMacro.\(id)")
    }
}

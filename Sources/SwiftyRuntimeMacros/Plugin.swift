import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftyRuntimePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ObjcMethodMacro.self,
        ObjcClassMethodMacro.self,
    ]
}

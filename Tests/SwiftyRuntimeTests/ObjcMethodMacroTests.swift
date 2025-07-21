import Foundation
import XCTest
import Testing
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import SwiftyRuntime

#if canImport(SwiftyRuntimeMacros)
@testable import SwiftyRuntimeMacros

let testMacros: [String: Macro.Type] = [
    "objcMethod": ObjcMethodMacro.self,
    "objcClassMethod": ObjcClassMethodMacro.self,
]
#endif

final class ObjcMethodMacroTests: XCTestCase {
    
    func testObjcMethodMacro() throws {
#if canImport(SwiftyRuntimeMacros)
        assertMacroExpansion(
            """
            #objcMethod("pathForResource:ofType:", of: Bundle.self, as: ((NSString, NSString) -> NSString).self)
            """,
            expandedSource: """
            { () -> ((AnyObject) -> ((NSString, NSString) -> NSString))? in
                let __macro_local_16SelectorVariablefMu_ = NSSelectorFromString("pathForResource:ofType:")
                guard let __macro_local_14MethodVariablefMu_ = class_getInstanceMethod(Bundle.self, __macro_local_16SelectorVariablefMu_) else {
                    return nil
                }
                let __macro_local_11ImpVariablefMu_ = method_getImplementation(__macro_local_14MethodVariablefMu_)
                let __macro_local_16TypedImpVariablefMu_ = unsafeBitCast(
                    __macro_local_11ImpVariablefMu_,
                    to: (@convention(c) (AnyObject, Selector, NSString, NSString) -> NSString).self
                )
                return { target in
                    return {
                        return __macro_local_16TypedImpVariablefMu_(target, __macro_local_16SelectorVariablefMu_, $0, $1)
                    }
                }
            }()
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
    
    func testObjcClassMethodMacro() throws {
#if canImport(SwiftyRuntimeMacros)
        assertMacroExpansion(
            """
            #objcClassMethod("mainBundle", of: Bundle.self, as: (() -> Bundle).self)
            """,
            expandedSource: """
            { () -> (() -> Bundle)? in
                let __macro_local_16SelectorVariablefMu_ = NSSelectorFromString("mainBundle")
                guard let __macro_local_14MethodVariablefMu_ = class_getClassMethod(Bundle.self, __macro_local_16SelectorVariablefMu_) else {
                    return nil
                }
                let __macro_local_11ImpVariablefMu_ = method_getImplementation(__macro_local_14MethodVariablefMu_)
                let __macro_local_16TypedImpVariablefMu_ = unsafeBitCast(
                    __macro_local_11ImpVariablefMu_,
                    to: (@convention(c) (AnyObject, Selector) -> Bundle).self
                )
                return {
                    return __macro_local_16TypedImpVariablefMu_(Bundle.self, __macro_local_16SelectorVariablefMu_)
                }
            }()
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
}

@Suite
struct ObjcMethodMacroRuntimeTests {
    
    @Test func testObjcMethodMacro() throws {
        let invokerFactory = try #require(#objcMethod(
            "timeIntervalSinceDate:", of: NSDate.self,
            as: ((NSDate) -> TimeInterval).self
        ))
        
        let fixtureDate1 = NSDate(timeIntervalSince1970: 10)
        let fixtureDate2 = NSDate(timeIntervalSince1970: 20)
        
        let invoker = invokerFactory(fixtureDate2)
        #expect(invoker(fixtureDate1) == 10)
    }
    
    @Test func testObjcClassMethodMacro() throws {
        let invoker = try #require(#objcClassMethod(
            "standardUserDefaults", of: UserDefaults.self,
            as: (() -> UserDefaults).self
        ))
        let userDefaults = invoker()
        #expect(type(of: userDefaults) == UserDefaults.self)
    }
}

/// Creates an invoker for the specified Objective-C method.
///
/// - Parameters:
///   - selector: The selector to an instance method to invoke.
///   - cls: The class that defines the method to invoke.
///   - type: A type for the produced closure. You should specify a closure type
///     that is compatible with the method to invoke.
/// - Returns: An optional closure that receives the target and then returns the
///   method invoker, `nil` if the method is not found on the specified class.
/// - SeeAlso: Use ``objcClassMethod(_:of:as:)`` for class method.
@freestanding(expression)
public macro objcMethod<F>(
    _ selector: String,
    of cls: AnyClass,
    as type: F.Type
) -> ((AnyObject) -> F)? = #externalMacro(module: "SwiftyRuntimeMacros", type: "ObjcMethodMacro")

/// Creates an invoker for the specified Objective-C class method.
///
/// - Parameters:
///   - selector: The selector to a class method to invoke.
///   - cls: The class that defines the method to invoke.
///   - type: A type for the produced closure. You should specify a closure type
///     that is compatible with the method to invoke.
/// - Returns: An optional closure that acts as the method invoker, `nil` if the
///   method is not found on the specified class.
@freestanding(expression)
public macro objcClassMethod<F>(
    _ selector: String,
    of cls: AnyClass,
    as type: F.Type
) -> F? = #externalMacro(module: "SwiftyRuntimeMacros", type: "ObjcClassMethodMacro")

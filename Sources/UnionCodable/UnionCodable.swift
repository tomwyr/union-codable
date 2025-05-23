/// A macro that makes an enum conform to `Codable` using a discriminator field
/// for decoding and encoding.
///
/// The macro can be attached to enums with cases following these conventions:
/// - Enums with no associated values
/// - Enums with a single positional associated value
/// - Enums with only named associated values
///
/// The generated implementation encodes the associated values and includes the
/// case name under the key specified by `discriminator`.
///
/// Example:
/// ```swift
/// @UnionCodable(discriminator: "kind")
/// enum Shape {
///   case circle(radius: Double)
///   case rectangle(width: Double, height: Double)
/// }
/// ```
/// JSON output for `.circle(radius: 5.0)`:
/// ```json
/// {
///   "kind": "circle",
///   "radius": 5.0
/// }
/// ```
///
/// - Parameters:
///   - discriminator: The key used to identify the enum case in the encoded
///     data. If the discriminator conflicts with any associated value keys,
///     the macro will throw. Defaults to `"type"`.
@attached(
  extension,
  names: named(CodingKeys), named(init(from:)), named(encode(to:))
)
public macro UnionCodable(discriminator: String = "type") =
  #externalMacro(module: "UnionCodableMacros", type: "UnionCodableMacro")

@attached(
  extension,
  names: named(CodingKeys), named(init(from:)), named(encode(to:))
)
public macro UnionCodable(discriminator: String = "type") =
  #externalMacro(module: "UnionCodableMacros", type: "UnionCodableMacro")

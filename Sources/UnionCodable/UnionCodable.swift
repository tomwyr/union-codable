@attached(member)
public macro UnionCodable(discriminator: String = "type") =
  #externalMacro(module: "UnionCodableMacros", type: "UnionCodableMacro")

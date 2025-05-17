@attached(peer)
public macro UnionCodable(discriminator: String = "type") =
  #externalMacro(module: "UnionCodableMacros", type: "UnionCodableMacro")

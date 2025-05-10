@attached(member)
public macro UnionCodable(discriminatorKey: String = "type") =
  #externalMacro(module: "UnionCodableMacros", type: "UnionCodableMacro")

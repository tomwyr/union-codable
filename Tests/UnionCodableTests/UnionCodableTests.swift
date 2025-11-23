import Testing

@testable import UnionCodableMacros

@Suite(.macros([UnionCodableMacro.self]))
struct UnionCodableTest {}

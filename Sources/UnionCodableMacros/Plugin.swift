import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct UnionCodablePlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    UnionCodableMacro.self
  ]
}

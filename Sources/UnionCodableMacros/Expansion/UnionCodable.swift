import SwiftSyntax
import SwiftSyntaxMacros

public struct UnionCodableMacro: ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws(UnionCodableError) -> [ExtensionDeclSyntax] {
    let config = try extractMacroConfig(node: node)
    let target = try parseMacroTarget(declaration: declaration, config: config)
    return try expandMacro(config: config, target: target)
  }
}

struct UnionCodableConfig {
  var discriminator: String
}

struct UnionCodableTarget {
  var name: String
  var cases: [EnumCase]
}

struct EnumCase {
  let name: String
  let params: EnumCaseParams
}

enum EnumCaseParams {
  case none
  case positional(type: String)
  case named(params: [NamedParam])
}

typealias NamedParam = (name: String, type: String)

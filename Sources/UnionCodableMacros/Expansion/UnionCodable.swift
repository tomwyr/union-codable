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
  var layout: UnionCodableLayout

  static func defaults() -> UnionCodableConfig {
    .init(discriminator: "type", layout: .flat)
  }
}

enum UnionCodableLayout {
  case flat
  case nested(key: String)

  static func nestedDefaults(key: String? = nil) -> UnionCodableLayout {
    .nested(key: key ?? "value")
  }
}

struct UnionCodableTarget {
  var name: String
  var cases: [EnumCase]

  var hasAnyParam: Bool {
    cases.compactMap { $0.params }.contains {
      if case .none = $0 { false } else { true }
    }
  }

  var hasNamedParam: Bool {
    cases.compactMap { $0.params }.contains {
      if case .named = $0 { true } else { false }
    }
  }
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

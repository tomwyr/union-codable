import SwiftSyntax
import SwiftSyntaxMacros

/*
Requirements:
- No params
- Named params only
- Single positional param
  - Cannot be enum
  - Cannot conflict with discriminator
*/
public struct UnionCodableMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext
  ) throws(UnionCodableError) -> [DeclSyntax] {
    guard let config = extractMacroConfig(node) else {
      throw .invalidDeclaration
    }
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      throw .invalidTarget
    }

    let target = enumDecl.name.text
    let cases = extractEnumCases(enumDecl)

    try validateEnumCases(cases: cases, config: config)

    return [
      expandCodingKeys(target: target, cases: cases, config: config),
      expandEncoding(target: target, cases: cases),
      expandDecoding(target: target, cases: cases),
    ]
  }
}

extension UnionCodableMacro {
  private static func extractMacroConfig(_ node: AttributeSyntax) -> UnionCodableConfig? {
    var config = UnionCodableConfig()

    guard case let .argumentList(argsList) = node.arguments else {
      return config
    }

    if let discriminator = extractStringArg(name: "discriminator", from: argsList) {
      config.discriminator = discriminator
    }

    return config
  }

  private static func extractStringArg(name: String, from argsList: LabeledExprListSyntax)
    -> String?
  {
    let matchedArgs = argsList.filter { arg in arg.label?.identifier?.name == name }
    guard matchedArgs.count == 1, let matchedArg = matchedArgs.first,
      let argExpr = matchedArg.expression.as(StringLiteralExprSyntax.self)
    else {
      return nil
    }
    return argExpr.segments.joined()
  }

  private static func extractEnumCases(_ enumDecl: EnumDeclSyntax) -> [EnumCase] {
    enumDecl.memberBlock.members.flatMap { member -> [EnumCase] in
      guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
        return []
      }

      return caseDecl.elements.map { element in
        let name = element.name.text
        let params = element.parameterClause?.parameters.map { param in
          (name: param.firstName?.text, type: param.type.description)
        }
        return (name: name, params: params)
      }
    }
  }

  private static func validateEnumCases(
    cases: [EnumCase],
    config: UnionCodableConfig
  ) throws(UnionCodableError) {
    for (name, params) in cases {
      guard let params else { continue }

      let (positional, named) = params.split { (name, _) in name == nil }
      guard positional.count == 0 || named.count == 0 else {
        throw .ambiguousPayload
      }
      guard !named.map(\.name).contains(config.discriminator) else {
        throw .discriminatorConflict(caseName: name)
      }
    }
  }
}

extension UnionCodableMacro {
  private static func expandCodingKeys(
    target: String, cases: [EnumCase],
    config: UnionCodableConfig,
  )
    -> DeclSyntax
  {
    return """
      extension \(raw: target) {
        fileprivate enum CodingKeys: String, CodingKey {
          case discriminator = "\(raw: config.discriminator)"
        }
      }
      """
  }

  private static func expandEncoding(target: String, cases: [EnumCase])
    -> DeclSyntax
  {
    """
    extension \(raw: target): Encodable {
      func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        \(raw: cases.mapLines { """
        case .\($0.name):
          try container.encode("\($0.name)", forKey: .discriminator)
        """
        }.padded(4))
        }
      }
    }
    """
  }

  private static func expandDecoding(target: String, cases: [EnumCase])
    -> DeclSyntax
  {
    """
    extension \(raw: target): Decodable {
      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let discriminator = try container.decode(String.self, forKey: .discriminator)

        switch discriminator {
        \(raw: cases.mapLines { """
        case "\($0.name)":
          self = .\($0.name)
        """
        }.padded(4))
        default:
          throw DecodingError.dataCorruptedError(
            forKey: .discriminator, in: container, 
            debugDescription: "Unknown union discriminator: \\(discriminator)"
          )
        }
      }
    }
    """
  }
}

struct UnionCodableConfig {
  var discriminator: String = "type"
}

typealias EnumCase = (name: String, params: [(name: String?, type: String)]?)

extension Array {
  func mapLines(transform: (Element) -> String) -> String {
    map(transform).joined(separator: "\n")
  }

  func split(by predicate: (Element) -> Bool) -> ([Element], [Element]) {
    var first: [Element] = []
    var second: [Element] = []
    for item in self {
      if predicate(item) {
        first.append(item)
      } else {
        second.append(item)
      }
    }
    return (first, second)
  }
}

extension String {
  func padded(_ count: Int) -> String {
    let padding = String(repeating: " ", count: count)
    return split(separator: "\n").joined(separator: "\n" + padding)
  }
}

extension StringLiteralSegmentListSyntax {
  func joined() -> String {
    compactMap { segment in
      segment.as(StringSegmentSyntax.self)?.content.text
    }.joined()
  }
}

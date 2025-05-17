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
    guard let macroConfig = extractMacroConfig(node) else {
      throw .invalidDeclaration
    }
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      throw .invalidTarget
    }

    let target = enumDecl.name.text
    let discriminator = macroConfig.discriminator
    let cases = try extractEnumCases(enumDecl)

    return [
      expandCodingKeys(target: target, discriminator: discriminator, cases: cases),
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

  private static func extractEnumCases(
    _ enumDecl: EnumDeclSyntax,
  ) throws(UnionCodableError) -> [EnumCase] {
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
}

extension UnionCodableMacro {
  private static func expandCodingKeys(target: String, discriminator: String, cases: [EnumCase])
    -> DeclSyntax
  {
    return """
      extension \(raw: target) {
        fileprivate enum CodingKeys: String, CodingKey {
          case discriminator = "\(raw: discriminator)"
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

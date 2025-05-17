import SwiftSyntax
import SwiftSyntaxMacros

public struct UnionCodableMacro: PeerMacro {
  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws(UnionCodableError) -> [DeclSyntax] {
    guard let config = extractMacroConfig(node) else {
      throw .invalidDeclaration
    }
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      throw .invalidTarget
    }

    let target = enumDecl.name.text
    let cases = extractEnumCases(enumDecl)

    try validateEnumCases(cases, config)

    return [
      expandCodingKeys(target, cases, config),
      expandEncoding(target, cases, config),
      expandDecoding(target, cases, config),
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
        let params =
          element.parameterClause?.parameters.map { param in
            (name: param.firstName?.text, type: param.type.description)
          } ?? []
        return (name: name, params: params)
      }
    }
  }

  private static func validateEnumCases(
    _ cases: [EnumCase],
    _ config: UnionCodableConfig
  ) throws(UnionCodableError) {
    for (name, params) in cases {
      let (positional, named) = params.split { name, _ in name == nil }
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
    _ target: String, _ cases: [EnumCase],
    _ config: UnionCodableConfig,
  ) -> DeclSyntax {
    let keys = [config.discriminator] + cases.flatMap { $0.params.compactMap(\.name) }

    return """
      extension \(raw: target) {
        fileprivate enum CodingKeys: String, CodingKey {
          case \(raw: keys.joined(separator: ", "))
        }
      }
      """
  }

  private static func expandEncoding(
    _ target: String, _ cases: [EnumCase],
    _ config: UnionCodableConfig,
  ) -> DeclSyntax {
    """
    extension \(raw: target): Encodable {
      func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        \(raw: cases.mapLines { """
        \(expandCaseClause($0))
          \(expandCaseEncoding($0, config).padded(2))
        """ }.padded(4))
        }
      }
    }
    """
  }

  private static func expandCaseClause(_ enumCase: EnumCase) -> String {
    let namedParams = enumCase.params.compactMap(\.name).joined(separator: ", ")

    return if namedParams.isEmpty {
      """
      case .\(enumCase.name):
      """
    } else {
      """
      case let .\(enumCase.name)(\(namedParams)):
      """
    }
  }

  private static func expandCaseEncoding(
    _ enumCase: EnumCase, _ config: UnionCodableConfig,
  ) -> String {
    let encodeDiscriminator = """
      try container.encode("\(enumCase.name)", forKey: .\(config.discriminator))
      """
    let encodeParams = enumCase.params.compactMap(\.name).mapLines {
      """
      try container.encode(\($0), forKey: .\($0))   
      """
    }

    return if !encodeParams.isEmpty {
      """
      \(encodeDiscriminator)
      \(encodeParams)
      """
    } else {
      """
      \(encodeDiscriminator)
      """
    }
  }

  private static func expandDecoding(
    _ target: String, _ cases: [EnumCase],
    _ config: UnionCodableConfig,
  ) -> DeclSyntax {
    let discriminator: DeclSyntax = "\(raw: config.discriminator)"

    return """
      extension \(raw: target): Decodable {
        init(from decoder: any Decoder) throws {
          let container = try decoder.container(keyedBy: CodingKeys.self)
          let \(discriminator) = try container.decode(String.self, forKey: .\(discriminator))

          switch \(discriminator) {
          \(raw: cases.mapLines { """
          case "\($0.name)":
            \(expandCaseDecoding($0).padded(2))
          """ }.padded(4))
          default:
            throw DecodingError.dataCorruptedError(
              forKey: .\(discriminator), in: container, 
              debugDescription: "Unknown union \(discriminator): \\(\(discriminator))"
            )
          }
        }
      }
      """
  }

  private static func expandCaseDecoding(_ enumCase: EnumCase) -> String {
    let namedParams = enumCase.params.compactMap { name, type in
      if let name { (name: name, type: type, last: false) } else { nil }
    }

    return if namedParams.isEmpty {
      """
      self = .\(enumCase.name)
      """
    } else {
      """
      self = .\(enumCase.name)(
      \(namedParams.mapLines(separator: ",") { """
        \($0.name): try container.decode(\($0.type).self, forKey: .\($0.name))
      """})
      )
      """
    }
  }
}

struct UnionCodableConfig {
  var discriminator: String = "type"
}

typealias EnumCase = (name: String, params: [(name: String?, type: String)])

extension Array {
  func mapLines(separator: String = "", transform: (Element) -> String) -> String {
    map(transform).joined(separator: separator + "\n")
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

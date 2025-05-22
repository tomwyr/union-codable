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
    guard let config = extractMacroConfig(node) else {
      throw .invalidDeclaration
    }
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      throw .invalidTarget
    }

    let target = enumDecl.name.text
    let cases = extractEnumCases(enumDecl)

    try validateEnumCases(cases, config)

    return try [
      expandCodingKeys(target, cases, config),
      expandEncoding(target, cases, config),
      expandDecoding(target, cases, config),
    ].asExtensionDeclarations()
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
      guard
        (positional.count == 0 && named.count == 0)
          || (positional.count == 1 && named.count == 0)
          || (positional.count == 0 && named.count > 0)
      else {
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
        \(raw: cases.lineJoined { """
        \(expandCaseClause($0))
          \(expandCaseEncoding($0, config).linePadded(2))
        """ }.linePadded(4))
        }
      }
    }
    """
  }

  private static func expandCaseClause(_ enumCase: EnumCase) -> String {
    let hasPositionalParam = enumCase.params.count { $0.name == nil } == 1
    let namedParams = enumCase.params.compactMap(\.name).joined(separator: ", ")

    return if hasPositionalParam {
      """
      case let .\(enumCase.name)(value):
      """
    } else if !namedParams.isEmpty {
      """
      case let .\(enumCase.name)(\(namedParams)):
      """
    } else {
      """
      case .\(enumCase.name):
      """
    }
  }

  private static func expandCaseEncoding(
    _ enumCase: EnumCase, _ config: UnionCodableConfig,
  ) -> String {
    let encodeDiscriminator = """
      try container.encode("\(enumCase.name)", forKey: .\(config.discriminator))
      """
    let hasPositionalParam = enumCase.params.count { $0.name == nil } == 1
    let namedParams = enumCase.params.compactMap(\.name)

    return if hasPositionalParam {
      """
      \(encodeDiscriminator)
      try value.encode(to: encoder)
      """
    } else if !namedParams.isEmpty {
      """
      \(encodeDiscriminator)
      \(namedParams.lineJoined { """
      try container.encode(\($0), forKey: .\($0))   
      """ })
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
          \(raw: cases.lineJoined { """
          case "\($0.name)":
            \(expandCaseDecoding($0).linePadded(2))
          """ }.linePadded(4))
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
    var positionalParam: (name: String?, type: String)?
    if enumCase.params.count == 1, let param = enumCase.params.first, param.name == nil {
      positionalParam = param
    }
    let namedParams = enumCase.params.compactMap { name, type in
      if let name { (name: name, type: type) } else { nil }
    }

    return if let positionalParam {
      """
      self = .\(enumCase.name)(try \(positionalParam.type)(from: decoder))
      """
    } else if namedParams.isEmpty {
      """
      self = .\(enumCase.name)
      """
    } else {
      """
      self = .\(enumCase.name)(
      \(namedParams.lineJoined(suffix: ",") { """
        \($0.name): try container.decode(\($0.type).self, forKey: .\($0.name))
      """})
      )
      """
    }
  }
}

extension [DeclSyntax] {
  func asExtensionDeclarations() throws(UnionCodableError) -> [ExtensionDeclSyntax] {
    var result = [ExtensionDeclSyntax]()
    for decl in self {
      guard let extDecl = decl.as(ExtensionDeclSyntax.self) else {
        throw .invalidExpansion
      }
      result.append(extDecl)
    }
    return result
  }
}

struct UnionCodableConfig {
  var discriminator: String = "type"
}

typealias EnumCase = (name: String, params: [(name: String?, type: String)])

extension Array {
  func lineJoined(suffix: String = "", transform: (Element) -> String) -> String {
    map(transform).joined(separator: suffix + "\n")
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
  func linePadded(_ count: Int) -> String {
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

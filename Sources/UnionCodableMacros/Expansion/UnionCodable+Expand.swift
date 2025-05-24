import SwiftSyntax

extension UnionCodableMacro {
  static func expandMacro(
    config: UnionCodableConfig,
    target: UnionCodableTarget,
  ) throws(UnionCodableError) -> [ExtensionDeclSyntax] {
    try [
      expandCodingKeys(config, target),
      expandEncoding(config, target),
      expandDecoding(config, target),
    ].asExtensionDeclarations()
  }

  private static func expandCodingKeys(
    _ config: UnionCodableConfig,
    _ target: UnionCodableTarget,
  ) -> DeclSyntax {
    let caseNames = target.cases.flatMap {
      return switch $0.params {
      case let .named(params): params.map(\.name)
      case .none, .positional: [String]()
      }
    }
    let keys = ([config.discriminator] + caseNames).uniqued()

    return """
      extension \(raw: target.name) {
        fileprivate enum CodingKeys: String, CodingKey {
          case \(raw: keys.joined(separator: ", "))
        }
      }
      """
  }

  private static func expandEncoding(
    _ config: UnionCodableConfig,
    _ target: UnionCodableTarget,
  ) -> DeclSyntax {
    """
    extension \(raw: target.name) {
      func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        \(raw: target.cases.lineJoined { """
        \(expandCaseClause($0))
          \(expandCaseEncoding($0, config).linePadded(2))
        """ }.linePadded(4))
        }
      }
    }
    """
  }

  private static func expandDecoding(
    _ config: UnionCodableConfig,
    _ target: UnionCodableTarget,
  ) -> DeclSyntax {
    let discriminator: DeclSyntax = "\(raw: config.discriminator)"

    return """
      extension \(raw: target.name) {
        init(from decoder: any Decoder) throws {
          let container = try decoder.container(keyedBy: CodingKeys.self)
          let \(discriminator) = try container.decode(String.self, forKey: .\(discriminator))

          switch \(discriminator) {
          \(raw: target.cases.lineJoined { """
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

  private static func expandCaseClause(_ enumCase: EnumCase) -> String {
    switch enumCase.params {
    case .none:
      """
      case .\(enumCase.name):
      """
    case .positional:
      """
      case let .\(enumCase.name)(value):
      """
    case let .named(params):
      """
      case let .\(enumCase.name)(\(params.map(\.name).joined(separator: ", "))):
      """
    }
  }

  private static func expandCaseEncoding(
    _ enumCase: EnumCase, _ config: UnionCodableConfig,
  ) -> String {
    let encodeDiscriminator = """
      try container.encode("\(enumCase.name)", forKey: .\(config.discriminator))
      """

    return switch enumCase.params {
    case .none:
      """
      \(encodeDiscriminator)
      """
    case .positional:
      """
      \(encodeDiscriminator)
      try value.encode(to: encoder)
      """
    case let .named(params):
      """
      \(encodeDiscriminator)
      \(params.map(\.name).lineJoined { """
      try container.encode(\($0), forKey: .\($0))   
      """ })
      """
    }
  }

  private static func expandCaseDecoding(_ enumCase: EnumCase) -> String {
    switch enumCase.params {
    case .none:
      """
      self = .\(enumCase.name)
      """
    case let .positional(type):
      """
      self = .\(enumCase.name)(try \(type)(from: decoder))
      """
    case let .named(params):
      """
      self = .\(enumCase.name)(
      \(params.lineJoined(suffix: ",") { """
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

extension String {
  func linePadded(_ count: Int) -> String {
    let padding = String(repeating: " ", count: count)
    return split(separator: "\n").joined(separator: "\n" + padding)
  }
}

extension Array {
  func lineJoined(suffix: String = "", transform: (Element) -> String) -> String {
    map(transform).joined(separator: suffix + "\n")
  }
}

extension Array where Element: Hashable {
  func uniqued() -> [Element] {
    var seen = Set<Element>()
    return self.filter { seen.insert($0).inserted }
  }
}

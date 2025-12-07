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
    let caseNames = target.cases.flatMap { enumCase in
      switch enumCase.params {
      case .named(let params): params.map(\.name)
      case .none, .positional: [String]()
      }
    }

    let keys = {
      switch config.layout {
      case .flat:
        return ([config.discriminator] + caseNames).uniqued()
      case .nested(key: let valueKey):
        var keys = [config.discriminator]
        if target.hasAnyParam {
          keys.append(valueKey)
        }
        return keys
      }
    }()

    let valueKeys =
      switch config.layout {
      case .flat: [String]()
      case .nested: caseNames
      }

    return if valueKeys.isEmpty {
      """
      extension \(raw: target.name) {
        fileprivate enum CodingKeys: String, CodingKey {
          case \(raw: keys.joined(separator: ", "))
        }
      }
      """
    } else {
      """
      extension \(raw: target.name) {
        fileprivate enum CodingKeys: String, CodingKey {
          case \(raw: keys.joined(separator: ", "))
        }

        fileprivate enum ValueCodingKeys: String, CodingKey {
          case \(raw: valueKeys.joined(separator: ", "))
        }
      }
      """
    }
  }

  private static func expandEncoding(
    _ config: UnionCodableConfig,
    _ target: UnionCodableTarget,
  ) -> DeclSyntax {
    let visibility: DeclSyntax = target.external ? "public " : ""
    let containers =
      switch config.layout {
      case .nested(key: let valueKey) where target.hasNamedParam:
        """
        var container = encoder.container(keyedBy: CodingKeys.self)
        var valueContainer = container.nestedContainer(keyedBy: ValueCodingKeys.self, forKey: .\(valueKey))
        """

      default:
        """
        var container = encoder.container(keyedBy: CodingKeys.self)
        """
      }

    return """
      extension \(raw: target.name) {
        \(visibility)func encode(to encoder: any Encoder) throws {
          \(raw: containers)

          switch self {
          \(raw: target.cases.newlineJoined { expandCaseEncoding($0, config) }.newlinePadded(4))
          }
        }
      }
      """
  }

  private static func expandCaseEncoding(
    _ enumCase: EnumCase,
    _ config: UnionCodableConfig,
  ) -> String {
    let encodeDiscriminator = """
      try container.encode("\(enumCase.name)", forKey: .\(config.discriminator))
      """

    switch enumCase.params {
    case .none:
      return """
        case .\(enumCase.name):
          \(encodeDiscriminator)
        """

    case .positional:
      let encodeValue =
        switch config.layout {
        case .flat:
          """
          try value.encode(to: encoder)
          """

        case .nested(key: let valueKey):
          """
          try container.encode(value, forKey: .\(valueKey))
          """
        }

      return """
        case let .\(enumCase.name)(value):
          \(encodeDiscriminator)
          \(encodeValue)
        """

    case .named(let params):
      let container =
        switch config.layout {
        case .flat: "container"
        case .nested: "valueContainer"
        }

      return """
        case let .\(enumCase.name)(\(params.map(\.name).joined(separator: ", "))):
          \(encodeDiscriminator)
          \(params.newlineJoined { param in """
          try \(container).encode(\(param.name), forKey: .\(param.name))   
          """ }.newlinePadded(2))
        """
    }
  }

  private static func expandDecoding(
    _ config: UnionCodableConfig,
    _ target: UnionCodableTarget,
  ) -> DeclSyntax {
    let discriminator: DeclSyntax = "\(raw: config.discriminator)"
    let visibility: DeclSyntax = target.external ? "public " : ""
    let containers: DeclSyntax =
      switch config.layout {
      case .nested(key: let valueKey) where target.hasNamedParam:
        """
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let valueContainer = try container.nestedContainer(keyedBy: ValueCodingKeys.self, forKey: .\(raw: valueKey))
        """

      default:
        """
        let container = try decoder.container(keyedBy: CodingKeys.self)
        """
      }

    return """
      extension \(raw: target.name) {
        \(visibility)init(from decoder: any Decoder) throws {
          \(containers)
          let \(discriminator) = try container.decode(String.self, forKey: .\(discriminator))

          switch \(discriminator) {
          \(raw: target.cases.newlineJoined { expandCaseDecoding($0, config) }.newlinePadded(4))
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

  private static func expandCaseDecoding(
    _ enumCase: EnumCase,
    _ config: UnionCodableConfig,
  ) -> String {
    switch enumCase.params {
    case .none:
      return """
        case "\(enumCase.name)":
          self = .\(enumCase.name)
        """

    case .positional(let type):
      return switch config.layout {
      case .flat:
        """
        case "\(enumCase.name)":
          self = .\(enumCase.name)(try \(type)(from: decoder))
        """

      case .nested(key: let valueKey):
        """
        case "\(enumCase.name)":
          self = .\(enumCase.name)(try container.decode(\(type).self, forKey: .\(valueKey)))
        """
      }

    case .named(let params):
      let container =
        switch config.layout {
        case .flat: "container"
        case .nested: "valueContainer"
        }

      return """
        case "\(enumCase.name)":
          self = .\(enumCase.name)(
            \(params.newlineJoined { param in """
            \(param.name): try \(container).decode(\(param.type).self, forKey: .\(param.name)),
            """}.newlinePadded(4) )
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
  func newlinePadded(_ count: Int) -> String {
    let padding = String(repeating: " ", count: count)
    return split(separator: "\n").joined(separator: "\n" + padding)
  }
}

extension Array {
  func newlineJoined(transform: (Element) -> String) -> String {
    map(transform).joined(separator: "\n")
  }
}

extension Array where Element: Hashable {
  func uniqued() -> [Element] {
    var seen = Set<Element>()
    return self.filter { seen.insert($0).inserted }
  }
}

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
      case .named(let params): params.map(\.name)
      case .none, .positional: [String]()
      }
    }

    func expandKeys(name: String, keys: [String]) -> String {
      """
      fileprivate enum \(name): String, CodingKey {
        case \(keys.joined(separator: ", "))
      }
      """
    }

    func codingKeys() -> String {
      switch config.layout {
      case .flat:
        let keys = ([config.discriminator] + caseNames).uniqued()
        return expandKeys(name: "CodingKeys", keys: keys)

      case .nested(key: let valueKey):
        let rootKeys = [config.discriminator, valueKey]
        let valueKeys = caseNames

        return if valueKeys.isEmpty {
          expandKeys(name: "CodingKeys", keys: rootKeys)
        } else {
          """
          \(expandKeys(name: "CodingKeys", keys: rootKeys))
          \(expandKeys(name: "ValueCodingKeys", keys: valueKeys))
          """
        }
      }
    }

    return """
      extension \(raw: target.name) {
        \(raw: codingKeys().linePadded(2))
      }
      """
  }

  private static func expandEncoding(
    _ config: UnionCodableConfig,
    _ target: UnionCodableTarget,
  ) -> DeclSyntax {
    switch config.layout {
    case .nested(key: let valueKey) where target.hasNamedParam:
      """
      extension \(raw: target.name) {
        func encode(to encoder: any Encoder) throws {
          var container = encoder.container(keyedBy: CodingKeys.self)
          var valueContainer = container.nestedContainer(keyedBy: ValueCodingKeys.self, forKey: .\(raw: valueKey))

          switch self {
          \(raw: target.cases.lineJoined { """
      \(expandCaseClause($0))
        \(expandCaseEncoding($0, config).linePadded(2))
      """ }.linePadded(4))
          }
        }
      }
      """

    default:
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
  }

  private static func expandDecoding(
    _ config: UnionCodableConfig,
    _ target: UnionCodableTarget,
  ) -> DeclSyntax {
    let discriminator: DeclSyntax = "\(raw: config.discriminator)"
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
        init(from decoder: any Decoder) throws {
          \(containers)
          let \(discriminator) = try container.decode(String.self, forKey: .\(discriminator))

          switch \(discriminator) {
          \(raw: target.cases.lineJoined { """
          case "\($0.name)":
            \(expandCaseDecoding($0, config).linePadded(2))
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

    case .named(let params):
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
      switch config.layout {
      case .flat:
        """
        \(encodeDiscriminator)
        try value.encode(to: encoder)
        """

      case .nested(key: let valueKey):
        """
        \(encodeDiscriminator)
        try container.encode(value, forKey: .\(valueKey))
        """
      }

    case .named(let params):
      switch config.layout {
      case .flat:
        """
        \(encodeDiscriminator)
        \(params.map(\.name).lineJoined { """
        try container.encode(\($0), forKey: .\($0))   
        """ })
        """

      case .nested:
        """
        \(encodeDiscriminator)
        \(params.map(\.name).lineJoined { """
        try valueContainer.encode(\($0), forKey: .\($0))   
        """ })
        """
      }
    }
  }

  private static func expandCaseDecoding(
    _ enumCase: EnumCase, _ config: UnionCodableConfig,
  ) -> String {
    switch enumCase.params {
    case .none:
      return """
        self = .\(enumCase.name)
        """

    case .positional(let type):
      return switch config.layout {
      case .flat:
        """
        self = .\(enumCase.name)(try \(type)(from: decoder))
        """

      case .nested(key: let valueKey):
        """
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
        self = .\(enumCase.name)(
        \(params.lineJoined(suffix: ",") { """
          \($0.name): try \(container).decode(\($0.type).self, forKey: .\($0.name))
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

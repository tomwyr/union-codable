import SwiftSyntax
import SwiftSyntaxMacros

extension UnionCodableMacro {
  static func parseMacroTarget(declaration: DeclGroupSyntax, config: UnionCodableConfig)
    throws(UnionCodableError) -> UnionCodableTarget
  {
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      throw .invalidTarget
    }
    let name = enumDecl.name.text

    var enumCases = [EnumCase]()
    for member in enumDecl.memberBlock.members {
      guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
        continue
      }

      for element in caseDecl.elements {
        let caseName = element.name.text
        let rawParams =
          element.parameterClause?.parameters.map { param in
            (name: param.firstName?.text, type: param.type.description)
          } ?? []

        let caseParams = try resolveCaseParams(caseName, rawParams, config)
        let enumCase = EnumCase(name: caseName, params: caseParams)

        enumCases.append(enumCase)
      }
    }

    return UnionCodableTarget(name: name, cases: enumCases)
  }

  private static func resolveCaseParams(
    _ caseName: String,
    _ rawParams: [(name: String?, type: String)],
    _ config: UnionCodableConfig
  ) throws(UnionCodableError) -> EnumCaseParams {
    var positional = [String]()
    var named = [NamedParam]()
    for (name, type) in rawParams {
      if let name {
        named.append((name: name, type: type))
      } else {
        positional.append(type)
      }
    }

    let caseParams: EnumCaseParams =
      switch (positional.count, named.count) {
      case (0, 0): .none
      case (1, 0): .positional(type: positional.first!)
      case (0, 1...): .named(params: named)
      default: throw .ambiguousPayload
      }

    if case let .named(params) = caseParams {
      guard !params.map(\.name).contains(config.discriminator) else {
        throw .discriminatorConflict(caseName: caseName)
      }
    }

    return caseParams
  }
}

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
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      throw .invalidTarget
    }

    let cases = try extractEnumCases(enumDecl)

    return []
  }

  private static func extractEnumCases(
    _ enumDecl: EnumDeclSyntax,
  ) throws(UnionCodableError) -> [EnumCase] {
    enumDecl.memberBlock.members.compactMap { member in
      guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self),
        caseDecl.elements.count == 1,
        let element = caseDecl.elements.first
      else {
        return nil
      }

      let name = element.name.text
      let params = element.parameterClause?.parameters.map { param in
        (name: param.firstName?.text, type: param.type.description)
      }
      return (name: name, params: params)
    }
  }
}

typealias EnumCase = (name: String, params: [(name: String?, type: String)]?)

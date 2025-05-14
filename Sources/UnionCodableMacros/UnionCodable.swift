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

    let name = enumDecl.name.text
    let cases = try extractEnumCases(enumDecl)

    return [
      expandCodingKeys(name, cases)
    ]
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

  private static func expandCodingKeys(_ name: String, _ cases: [EnumCase]) -> DeclSyntax {
    let keyCases = cases.mapLines {
      "case \($0.name)"
    }

    return """
      extension \(raw: name) {
        fileprivate enum CodingKeys: String, CodingKey {
          \(raw: keyCases.padded(4))
        }
      }
      """
  }
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

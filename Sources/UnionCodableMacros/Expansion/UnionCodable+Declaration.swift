import SwiftSyntax
import SwiftSyntaxMacros

extension UnionCodableMacro {
  static func extractMacroConfig(node: AttributeSyntax)
    throws(UnionCodableError) -> UnionCodableConfig
  {
    var config = UnionCodableConfig(discriminator: "type")

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
}

extension StringLiteralSegmentListSyntax {
  func joined() -> String {
    compactMap { segment in
      segment.as(StringSegmentSyntax.self)?.content.text
    }.joined()
  }
}

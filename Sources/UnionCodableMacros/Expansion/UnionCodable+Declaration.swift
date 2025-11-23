import SwiftSyntax
import SwiftSyntaxMacros

extension UnionCodableMacro {
  static func extractMacroConfig(node: AttributeSyntax)
    throws(UnionCodableError) -> UnionCodableConfig
  {
    var config = UnionCodableConfig.defaults()

    guard case .argumentList(let argsList) = node.arguments else {
      return config
    }

    if let discriminator = extractStringArg(name: "discriminator", from: argsList) {
      config.discriminator = discriminator
    }

    if let layout = extractLayout(name: "layout", from: argsList) {
      config.layout = layout
    }

    if case .nested(key: let valueKey) = config.layout {
      if valueKey == config.discriminator {
        throw .discriminatorNestedValueConflict
      }
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

  private static func extractLayout(name: String, from argsList: LabeledExprListSyntax)
    -> UnionCodableLayout?
  {
    let matchedArgs = argsList.filter { arg in arg.label?.identifier?.name == name }
    guard matchedArgs.count == 1, let matchedArg = matchedArgs.first else {
      return nil
    }

    let argExpr = matchedArg.expression

    if let member = argExpr.as(MemberAccessExprSyntax.self) {
      let caseName = member.declName.baseName.text
      return caseName == "flat" ? .flat : nil
    }

    if let call = argExpr.as(FunctionCallExprSyntax.self),
      let member = call.calledExpression.as(MemberAccessExprSyntax.self)
    {
      let caseName = member.declName.baseName.text
      guard caseName == "nested" else {
        return nil
      }

      var argsByName = [String: LabeledExprListSyntax.Element]()
      for arg in call.arguments {
        guard let name = arg.label?.text else { continue }
        argsByName[name] = arg
      }

      var key: String? = nil
      if let keyArg = argsByName["key"],
        let keyLiteral = keyArg.expression.as(StringLiteralExprSyntax.self)
      {
        key = keyLiteral.segments.joined()
      }

      return .nestedDefaults(key: key)
    }

    return nil
  }
}

extension StringLiteralSegmentListSyntax {
  func joined() -> String {
    compactMap { segment in
      segment.as(StringSegmentSyntax.self)?.content.text
    }.joined()
  }
}

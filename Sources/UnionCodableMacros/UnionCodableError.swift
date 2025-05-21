import Foundation

public enum UnionCodableError: Error, LocalizedError {
  case invalidDeclaration
  case invalidTarget
  case ambiguousPayload
  case discriminatorConflict(caseName: String)
  case invalidExpansion

  public var errorDescription: String? {
    switch self {
    case .invalidDeclaration:
      "Unexpected format in UnionCodable macro"
    case .invalidTarget:
      "UnionCodable macro can only be applied to enums"
    case .ambiguousPayload:
      "UnionCodable macro supports only a single positional param or named params"
    case .discriminatorConflict(let caseName):
      "Discriminator conflict detected for case '\(caseName)'"
    case .invalidExpansion:
      "UnionCodable macro generated invalid code during expansion"
    }
  }
}

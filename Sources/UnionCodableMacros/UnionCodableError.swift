import Foundation

public enum UnionCodableError: Error, LocalizedError {
  case invalidDeclaration
  case invalidTarget

  public var errorDescription: String? {
    switch self {
    case .invalidDeclaration:
      "Unexpected format of the UnionCodable macro"
    case .invalidTarget:
      "The UnionCodable macro can only be applied to enums"
    }
  }
}

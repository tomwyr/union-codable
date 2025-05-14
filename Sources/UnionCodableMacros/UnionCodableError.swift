import Foundation

public enum UnionCodableError: Error, LocalizedError {
  case invalidTarget

  public var errorDescription: String? {
    switch self {
    case .invalidTarget:
      "The UnionCodable macro can only be applied to enums"
    }
  }
}

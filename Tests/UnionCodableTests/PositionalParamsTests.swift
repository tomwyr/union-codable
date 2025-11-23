import MacroTesting
import Testing

@testable import UnionCodableMacros

extension UnionCodableTest {
  @Test func casesWithPositionalParams() {
    assertMacro {
      """
      @UnionCodable
      enum Payment {
        case cash(Cash)
        case check(Check)
        case wire(Wire)
      }
      """
    } expansion: {
      """
      enum Payment {
        case cash(Cash)
        case check(Check)
        case wire(Wire)
      }

      extension Payment {
        fileprivate enum CodingKeys: String, CodingKey {
          case type
        }
      }

      extension Payment {
        func encode(to encoder: any Encoder) throws {
          var container = encoder.container(keyedBy: CodingKeys.self)

          switch self {
          case let .cash(value):
            try container.encode("cash", forKey: .type)
            try value.encode(to: encoder)
          case let .check(value):
            try container.encode("check", forKey: .type)
            try value.encode(to: encoder)
          case let .wire(value):
            try container.encode("wire", forKey: .type)
            try value.encode(to: encoder)
          }
        }
      }

      extension Payment {
        init(from decoder: any Decoder) throws {
          let container = try decoder.container(keyedBy: CodingKeys.self)
          let type = try container.decode(String.self, forKey: .type)

          switch type {
          case "cash":
            self = .cash(try Cash(from: decoder))
          case "check":
            self = .check(try Check(from: decoder))
          case "wire":
            self = .wire(try Wire(from: decoder))
          default:
            throw DecodingError.dataCorruptedError(
              forKey: .type, in: container,
              debugDescription: "Unknown union type: \\(type)"
            )
          }
        }
      }
      """
    }
  }
}

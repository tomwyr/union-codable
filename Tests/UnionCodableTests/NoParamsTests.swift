import MacroTesting
import Testing

@testable import UnionCodableMacros

extension UnionCodableTest {
  @Test func casesWithNoParamsMultiLine() {
    assertMacro {
      """
      @UnionCodable
      enum Direction {
        case up
        case down
        case left
        case right
      }
      """
    } expansion: {
      """
      enum Direction {
        case up
        case down
        case left
        case right
      }

      extension Direction {
        fileprivate enum CodingKeys: String, CodingKey {
          case type
        }
      }

      extension Direction {
        func encode(to encoder: any Encoder) throws {
          var container = encoder.container(keyedBy: CodingKeys.self)

          switch self {
          case .up:
            try container.encode("up", forKey: .type)
          case .down:
            try container.encode("down", forKey: .type)
          case .left:
            try container.encode("left", forKey: .type)
          case .right:
            try container.encode("right", forKey: .type)
          }
        }
      }

      extension Direction {
        init(from decoder: any Decoder) throws {
          let container = try decoder.container(keyedBy: CodingKeys.self)
          let type = try container.decode(String.self, forKey: .type)

          switch type {
          case "up":
            self = .up
          case "down":
            self = .down
          case "left":
            self = .left
          case "right":
            self = .right
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

  @Test func casesWithNoParamsSingleLine() {
    assertMacro {
      """
      @UnionCodable
      enum Direction {
        case up, down, left, right
      }
      """
    } expansion: {
      """
      enum Direction {
        case up, down, left, right
      }

      extension Direction {
        fileprivate enum CodingKeys: String, CodingKey {
          case type
        }
      }

      extension Direction {
        func encode(to encoder: any Encoder) throws {
          var container = encoder.container(keyedBy: CodingKeys.self)

          switch self {
          case .up:
            try container.encode("up", forKey: .type)
          case .down:
            try container.encode("down", forKey: .type)
          case .left:
            try container.encode("left", forKey: .type)
          case .right:
            try container.encode("right", forKey: .type)
          }
        }
      }

      extension Direction {
        init(from decoder: any Decoder) throws {
          let container = try decoder.container(keyedBy: CodingKeys.self)
          let type = try container.decode(String.self, forKey: .type)

          switch type {
          case "up":
            self = .up
          case "down":
            self = .down
          case "left":
            self = .left
          case "right":
            self = .right
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

  @Test func casesWithEmptyMacroConstructor() {
    assertMacro {
      """
      @UnionCodable()
      enum Direction {
        case up, down, left, right
      }
      """
    } expansion: {
      """
      enum Direction {
        case up, down, left, right
      }

      extension Direction {
        fileprivate enum CodingKeys: String, CodingKey {
          case type
        }
      }

      extension Direction {
        func encode(to encoder: any Encoder) throws {
          var container = encoder.container(keyedBy: CodingKeys.self)

          switch self {
          case .up:
            try container.encode("up", forKey: .type)
          case .down:
            try container.encode("down", forKey: .type)
          case .left:
            try container.encode("left", forKey: .type)
          case .right:
            try container.encode("right", forKey: .type)
          }
        }
      }

      extension Direction {
        init(from decoder: any Decoder) throws {
          let container = try decoder.container(keyedBy: CodingKeys.self)
          let type = try container.decode(String.self, forKey: .type)

          switch type {
          case "up":
            self = .up
          case "down":
            self = .down
          case "left":
            self = .left
          case "right":
            self = .right
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

  @Test func casesWithCustomDiscriminator() {
    assertMacro {
      """
      @UnionCodable(discriminator: "kind")
      enum Direction {
        case up, down, left, right
      }
      """
    } expansion: {
      """
      enum Direction {
        case up, down, left, right
      }

      extension Direction {
        fileprivate enum CodingKeys: String, CodingKey {
          case kind
        }
      }

      extension Direction {
        func encode(to encoder: any Encoder) throws {
          var container = encoder.container(keyedBy: CodingKeys.self)

          switch self {
          case .up:
            try container.encode("up", forKey: .kind)
          case .down:
            try container.encode("down", forKey: .kind)
          case .left:
            try container.encode("left", forKey: .kind)
          case .right:
            try container.encode("right", forKey: .kind)
          }
        }
      }

      extension Direction {
        init(from decoder: any Decoder) throws {
          let container = try decoder.container(keyedBy: CodingKeys.self)
          let kind = try container.decode(String.self, forKey: .kind)

          switch kind {
          case "up":
            self = .up
          case "down":
            self = .down
          case "left":
            self = .left
          case "right":
            self = .right
          default:
            throw DecodingError.dataCorruptedError(
              forKey: .kind, in: container,
              debugDescription: "Unknown union kind: \\(kind)"
            )
          }
        }
      }
      """
    }
  }
}

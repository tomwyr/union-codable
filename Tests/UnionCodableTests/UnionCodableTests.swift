import MacroTesting
import Testing

@testable import UnionCodableMacros

@Suite(.macros([UnionCodableMacro.self]))
struct UnionCodableTest {
  @Test func casesWithNoParamsMultiLine() async throws {
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

        extension Direction {
          fileprivate enum CodingKeys: String, CodingKey {
            case discriminator = "type"
          }
        }

        extension Direction: Encodable {
          func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .up:
              try container.encode("up", forKey: .discriminator)
            case .down:
              try container.encode("down", forKey: .discriminator)
            case .left:
              try container.encode("left", forKey: .discriminator)
            case .right:
              try container.encode("right", forKey: .discriminator)
            }
          }
        }

        extension Direction: Decodable {
          init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let discriminator = try container.decode(String.self, forKey: .discriminator)

            switch discriminator {
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
                forKey: .discriminator, in: container,
                debugDescription: "Unknown union discriminator: \\(discriminator)"
              )
            }
          }
        }
      }
      """
    }
  }

  @Test func casesWithNoParamsSingleLine() async throws {
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

        extension Direction {
          fileprivate enum CodingKeys: String, CodingKey {
            case discriminator = "type"
          }
        }

        extension Direction: Encodable {
          func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .up:
              try container.encode("up", forKey: .discriminator)
            case .down:
              try container.encode("down", forKey: .discriminator)
            case .left:
              try container.encode("left", forKey: .discriminator)
            case .right:
              try container.encode("right", forKey: .discriminator)
            }
          }
        }

        extension Direction: Decodable {
          init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let discriminator = try container.decode(String.self, forKey: .discriminator)

            switch discriminator {
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
                forKey: .discriminator, in: container,
                debugDescription: "Unknown union discriminator: \\(discriminator)"
              )
            }
          }
        }
      }
      """
    }
  }

  @Test func casesWithEmptyMacroConstructor() async throws {
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

        extension Direction {
          fileprivate enum CodingKeys: String, CodingKey {
            case discriminator = "type"
          }
        }

        extension Direction: Encodable {
          func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .up:
              try container.encode("up", forKey: .discriminator)
            case .down:
              try container.encode("down", forKey: .discriminator)
            case .left:
              try container.encode("left", forKey: .discriminator)
            case .right:
              try container.encode("right", forKey: .discriminator)
            }
          }
        }

        extension Direction: Decodable {
          init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let discriminator = try container.decode(String.self, forKey: .discriminator)

            switch discriminator {
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
                forKey: .discriminator, in: container,
                debugDescription: "Unknown union discriminator: \\(discriminator)"
              )
            }
          }
        }
      }
      """
    }
  }

  @Test func casesWithCustomDiscriminator() async throws {
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

        extension Direction {
          fileprivate enum CodingKeys: String, CodingKey {
            case discriminator = "kind"
          }
        }

        extension Direction: Encodable {
          func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .up:
              try container.encode("up", forKey: .discriminator)
            case .down:
              try container.encode("down", forKey: .discriminator)
            case .left:
              try container.encode("left", forKey: .discriminator)
            case .right:
              try container.encode("right", forKey: .discriminator)
            }
          }
        }

        extension Direction: Decodable {
          init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let discriminator = try container.decode(String.self, forKey: .discriminator)

            switch discriminator {
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
                forKey: .discriminator, in: container,
                debugDescription: "Unknown union discriminator: \\(discriminator)"
              )
            }
          }
        }
      }
      """
    }
  }
}

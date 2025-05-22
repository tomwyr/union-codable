import MacroTesting
import Testing

@testable import UnionCodableMacros

@Suite(.macros([UnionCodableMacro.self]))
struct UnionCodableTest {}

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

      extension Direction: Encodable {
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

      extension Direction: Decodable {
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

      extension Direction: Encodable {
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

      extension Direction: Decodable {
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

      extension Direction: Encodable {
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

      extension Direction: Decodable {
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

      extension Direction: Encodable {
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

      extension Direction: Decodable {
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

extension UnionCodableTest {
  @Test func casesWithNamedParams() {
    assertMacro {
      """
      @UnionCodable
      enum Resource {
        case loading(progress: Double)
        case data(length: Int, payload: String)
        case error
      }
      """
    } expansion: {
      """
      enum Resource {
        case loading(progress: Double)
        case data(length: Int, payload: String)
        case error
      }

      extension Resource {
        fileprivate enum CodingKeys: String, CodingKey {
          case type, progress, length, payload
        }
      }

      extension Resource: Encodable {
        func encode(to encoder: any Encoder) throws {
          var container = encoder.container(keyedBy: CodingKeys.self)

          switch self {
          case let .loading(progress):
            try container.encode("loading", forKey: .type)
            try container.encode(progress, forKey: .progress)
          case let .data(length, payload):
            try container.encode("data", forKey: .type)
            try container.encode(length, forKey: .length)
            try container.encode(payload, forKey: .payload)
          case .error:
            try container.encode("error", forKey: .type)
          }
        }
      }

      extension Resource: Decodable {
        init(from decoder: any Decoder) throws {
          let container = try decoder.container(keyedBy: CodingKeys.self)
          let type = try container.decode(String.self, forKey: .type)

          switch type {
          case "loading":
            self = .loading(
              progress: try container.decode(Double.self, forKey: .progress)
            )
          case "data":
            self = .data(
              length: try container.decode(Int.self, forKey: .length),
              payload: try container.decode(String.self, forKey: .payload)
            )
          case "error":
            self = .error
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

      extension Payment: Encodable {
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

      extension Payment: Decodable {
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

extension UnionCodableTest {
  @Test func casesWithDiscriminatorConflict() {
    assertMacro {
      """
      @UnionCodable
      enum Resource {
        case loading(progress: Double)
        case data(length: Int, type: String)
        case error
      }
      """
    } diagnostics: {
      """
      @UnionCodable
      ┬────────────
      ╰─ 🛑 discriminatorConflict(caseName: "data")
      enum Resource {
        case loading(progress: Double)
        case data(length: Int, type: String)
        case error
      }
      """
    }
  }

  @Test func casesWithCustomDiscriminatorConflict() {
    assertMacro {
      """
      @UnionCodable(discriminator: "resource")
      enum Resource {
        case loading(progress: Double)
        case data(length: Int, resource: String)
        case error
      }
      """
    } diagnostics: {
      """
      @UnionCodable(discriminator: "resource")
      ┬───────────────────────────────────────
      ╰─ 🛑 discriminatorConflict(caseName: "data")
      enum Resource {
        case loading(progress: Double)
        case data(length: Int, resource: String)
        case error
      }
      """
    }
  }

  @Test func casesWithMultiplePositionalParams() {
    assertMacro {
      """
      @UnionCodable
      enum Resource {
        case loading(progress: Double)
        case data(Int, String)
        case error
      }
      """
    } diagnostics: {
      """
      @UnionCodable
      ┬────────────
      ╰─ 🛑 ambiguousPayload
      enum Resource {
        case loading(progress: Double)
        case data(Int, String)
        case error
      }
      """
    }
  }

  @Test func casesWithMixedParamsTypes() {
    assertMacro {
      """
      @UnionCodable
      enum Resource {
        case loading(progress: Double)
        case data(Int, resource: String)
        case error
      }
      """
    } diagnostics: {
      """
      @UnionCodable
      ┬────────────
      ╰─ 🛑 ambiguousPayload
      enum Resource {
        case loading(progress: Double)
        case data(Int, resource: String)
        case error
      }
      """
    }
  }
}

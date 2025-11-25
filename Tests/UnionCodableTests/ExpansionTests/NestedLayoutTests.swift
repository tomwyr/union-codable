import MacroTesting
import Testing

@testable import UnionCodableMacros

extension UnionCodableTest {
  @Test func casesWithNoParamsAndNestedLayout() {
    assertMacro {
      """
      @UnionCodable(layout: .nested())
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

  @Test func casesWithNamedParamsAndNestedLayout() {
    assertMacro {
      """
      @UnionCodable(layout: .nested())
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
          case type, value
        }

        fileprivate enum ValueCodingKeys: String, CodingKey {
          case progress, length, payload
        }
      }

      extension Resource {
        func encode(to encoder: any Encoder) throws {
          var container = encoder.container(keyedBy: CodingKeys.self)
          var valueContainer = container.nestedContainer(keyedBy: ValueCodingKeys.self, forKey: .value)

          switch self {
          case let .loading(progress):
            try container.encode("loading", forKey: .type)
            try valueContainer.encode(progress, forKey: .progress)
          case let .data(length, payload):
            try container.encode("data", forKey: .type)
            try valueContainer.encode(length, forKey: .length)
            try valueContainer.encode(payload, forKey: .payload)
          case .error:
            try container.encode("error", forKey: .type)
          }
        }
      }

      extension Resource {
        init(from decoder: any Decoder) throws {
          let container = try decoder.container(keyedBy: CodingKeys.self)
          let valueContainer = try container.nestedContainer(keyedBy: ValueCodingKeys.self, forKey: .value)
          let type = try container.decode(String.self, forKey: .type)

          switch type {
          case "loading":
            self = .loading(
              progress: try valueContainer.decode(Double.self, forKey: .progress),
            )
          case "data":
            self = .data(
              length: try valueContainer.decode(Int.self, forKey: .length),
              payload: try valueContainer.decode(String.self, forKey: .payload),
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

  @Test func casesWithNamedParamsAndNestedLayoutWithCustomKey() {
    assertMacro {
      """
      @UnionCodable(layout: .nested(key: "data"))
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
          case type, data
        }

        fileprivate enum ValueCodingKeys: String, CodingKey {
          case progress, length, payload
        }
      }

      extension Resource {
        func encode(to encoder: any Encoder) throws {
          var container = encoder.container(keyedBy: CodingKeys.self)
          var valueContainer = container.nestedContainer(keyedBy: ValueCodingKeys.self, forKey: .data)

          switch self {
          case let .loading(progress):
            try container.encode("loading", forKey: .type)
            try valueContainer.encode(progress, forKey: .progress)
          case let .data(length, payload):
            try container.encode("data", forKey: .type)
            try valueContainer.encode(length, forKey: .length)
            try valueContainer.encode(payload, forKey: .payload)
          case .error:
            try container.encode("error", forKey: .type)
          }
        }
      }

      extension Resource {
        init(from decoder: any Decoder) throws {
          let container = try decoder.container(keyedBy: CodingKeys.self)
          let valueContainer = try container.nestedContainer(keyedBy: ValueCodingKeys.self, forKey: .data)
          let type = try container.decode(String.self, forKey: .type)

          switch type {
          case "loading":
            self = .loading(
              progress: try valueContainer.decode(Double.self, forKey: .progress),
            )
          case "data":
            self = .data(
              length: try valueContainer.decode(Int.self, forKey: .length),
              payload: try valueContainer.decode(String.self, forKey: .payload),
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

  @Test func casesWithPositionalParamsAndNestedLayout() {
    assertMacro {
      """
      @UnionCodable(layout: .nested())
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
          case type, value
        }
      }

      extension Payment {
        func encode(to encoder: any Encoder) throws {
          var container = encoder.container(keyedBy: CodingKeys.self)

          switch self {
          case let .cash(value):
            try container.encode("cash", forKey: .type)
            try container.encode(value, forKey: .value)
          case let .check(value):
            try container.encode("check", forKey: .type)
            try container.encode(value, forKey: .value)
          case let .wire(value):
            try container.encode("wire", forKey: .type)
            try container.encode(value, forKey: .value)
          }
        }
      }

      extension Payment {
        init(from decoder: any Decoder) throws {
          let container = try decoder.container(keyedBy: CodingKeys.self)
          let type = try container.decode(String.self, forKey: .type)

          switch type {
          case "cash":
            self = .cash(try container.decode(Cash.self, forKey: .value))
          case "check":
            self = .check(try container.decode(Check.self, forKey: .value))
          case "wire":
            self = .wire(try container.decode(Wire.self, forKey: .value))
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

  @Test func casesWithPositionalParamsAndNestedLayoutWithCustomKey() {
    assertMacro {
      """
      @UnionCodable(layout: .nested(key: "data"))
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
          case type, data
        }
      }

      extension Payment {
        func encode(to encoder: any Encoder) throws {
          var container = encoder.container(keyedBy: CodingKeys.self)

          switch self {
          case let .cash(value):
            try container.encode("cash", forKey: .type)
            try container.encode(value, forKey: .data)
          case let .check(value):
            try container.encode("check", forKey: .type)
            try container.encode(value, forKey: .data)
          case let .wire(value):
            try container.encode("wire", forKey: .type)
            try container.encode(value, forKey: .data)
          }
        }
      }

      extension Payment {
        init(from decoder: any Decoder) throws {
          let container = try decoder.container(keyedBy: CodingKeys.self)
          let type = try container.decode(String.self, forKey: .type)

          switch type {
          case "cash":
            self = .cash(try container.decode(Cash.self, forKey: .data))
          case "check":
            self = .check(try container.decode(Check.self, forKey: .data))
          case "wire":
            self = .wire(try container.decode(Wire.self, forKey: .data))
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

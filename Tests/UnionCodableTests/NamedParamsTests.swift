import MacroTesting
import Testing

@testable import UnionCodableMacros

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

      extension Resource {
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

      extension Resource {
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

  @Test func casesWithRepeatedNamedParams() {
    assertMacro {
      """
      @UnionCodable
      enum Resource {
        case loading(progress: Double)
        case data(length: Int, payload: String)
        case error(payload: String)
      }
      """
    } expansion: {
      """
      enum Resource {
        case loading(progress: Double)
        case data(length: Int, payload: String)
        case error(payload: String)
      }

      extension Resource {
        fileprivate enum CodingKeys: String, CodingKey {
          case type, progress, length, payload
        }
      }

      extension Resource {
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
          case let .error(payload):
            try container.encode("error", forKey: .type)
            try container.encode(payload, forKey: .payload)
          }
        }
      }

      extension Resource {
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
            self = .error(
              payload: try container.decode(String.self, forKey: .payload)
            )
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

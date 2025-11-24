import Foundation
import Testing

@testable import UnionCodable

@UnionCodable
enum Direction: Codable {
  case up, down, left, right
}

@UnionCodable(discriminator: "kind")
enum DirectionKindDiscriminator: Codable {
  case up, down, left, right
}

@UnionCodable
enum Resource: Codable, Equatable {
  case loading(progress: Double)
  case data(length: Int, payload: String)
  case error
}

@UnionCodable(discriminator: "kind")
enum ResourceKindDiscriminator: Codable, Equatable {
  case loading(progress: Double)
  case data(length: Int, payload: String)
  case error
}

@UnionCodable(layout: .nested(key: "body"))
enum ResourceBodyValueKey: Codable, Equatable {
  case loading(progress: Double)
  case data(length: Int, payload: String)
  case error
}

@UnionCodable
enum Payment: Codable, Equatable {
  case cash(Cash)
  case check(Check)
  case wire(Wire)
}

@UnionCodable(discriminator: "kind")
enum PaymentKindDiscriminator: Codable, Equatable {
  case cash(Cash)
  case check(Check)
  case wire(Wire)
}

@UnionCodable(layout: .nested(key: "body"))
enum PaymentBodyValueKey: Codable, Equatable {
  case cash(Cash)
  case check(Check)
  case wire(Wire)
}

struct Cash: Codable, Equatable {
  let value: Int
}
struct Check: Codable, Equatable {
  let value: Int
}
struct Wire: Codable, Equatable {
  let value: Int
}

func assertEncode<T>(object: () -> T, encodes expectedJson: () -> String) throws
where T: Codable {
  let encoder = JSONEncoder()
  // Sort keys to avoid non-deterministic data order in encoded jsons.
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  let data = try #require(try? encoder.encode(object()))
  let json = String(decoding: data, as: UTF8.self)
  #expect(json == expectedJson())
}

func assertDecode<T>(json: () -> String, decodes expectedObject: () -> T) throws
where T: Codable & Equatable {
  let data = try #require(json().data(using: .utf8))
  let decoder = JSONDecoder()
  let object = try #require(try? decoder.decode(T.self, from: data))
  #expect(object == expectedObject())
}

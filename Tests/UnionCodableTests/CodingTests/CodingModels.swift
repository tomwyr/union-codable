@testable import UnionCodable

@UnionCodable
enum Direction: Codable {
  case up, down, left, right
}

@UnionCodable
public enum ExternalDirection: Codable {
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

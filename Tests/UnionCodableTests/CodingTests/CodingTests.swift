import Foundation
import Testing

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

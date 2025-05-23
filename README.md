# Union Codable

A Swift macro implementing encoding/decoding of union-like types.

## Motivation

Swift enums with associated values lack native support for discriminator-based keyed encoding, making it difficult to serialize union types in a way that aligns with common external API formats. Manual Codable implementations can be verbose, error-prone, and require duplicating case-handling logic and type mapping.

`UnionCodable` addresses this by generating `Codable` conformance that uses a discriminator key to handle encoding and decoding automatically, enabling concise and reliable serialization of polymorphic data.

## Usage

Annotate your enum with `@UnionCodable`, specifying the discriminator key if necessary. Each case or associated type must provide a unique discriminator value.

```swift
@UnionCodable(discriminator: "kind")
enum Shape: Codable {
  case circle(radius: Double)
  case rectangle(width: Double, height: Double)
}
```

The macro will generate `Codable` conformance encoding to/decoding from the following JSON structure (e.g. `.circle(radius: 5.0)`):
```json
{
  "kind": "circle",
  "radius": 5.0
}
```

The same behavior applies when enum cases are declared using positional parameters for their associated types.

```swift
@UnionCodable
enum Shape: Codable {
  case circle(Circle)
  case rectangle(Rectangle)
}

struct Circle: Codable {
  let radius: Double
}

struct Rectangle: Codable {
  let width: Double
  let height: Double
}
```

The macro will generate `Codable` conformance encoding to/decoding from the following JSON structure (e.g. `.rectangle(.init(width: 4.0, height: 10.0))`):
```json
{
  "type": "rectangle",
  "width": 4.0,
  "height": 10.0
}
```

> [!NOTE]
> Because `@UnionCodable` only expands to `init(from:)` and `encode(to:)` method implementations, the annotated enum must still explicitly conform to the `Codable` protocol.
>
> This is intentional, allowing `@UnionCodable` to be removed without code changes while maintaining uniform Codable declarations across types.

## Contributing

Contributions are welcome. Please open issues for bugs or feature requests. For code changes, fork the repo, create a feature branch, and submit a pull request including necessary context and adequate test coverage.

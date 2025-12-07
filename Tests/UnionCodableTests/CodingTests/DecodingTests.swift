import Testing

extension UnionCodableTest {
  @Test func decodingNoParams() throws {
    try assertDecode {
      """
      {
        "type" : "right"
      }
      """
    } decodes: {
      Direction.right
    }
  }

  @Test func decodingExternalType() throws {
    try assertDecode {
      """
      {
        "type" : "right"
      }
      """
    } decodes: {
      ExternalDirection.right
    }
  }

  @Test func decodingNoParamsWithCustomDiscriminator() throws {
    try assertDecode {
      """
      {
        "kind" : "right"
      }
      """
    } decodes: {
      DirectionKindDiscriminator.right
    }
  }

  @Test func decodingNamedParams() throws {
    try assertDecode {
      """
      {
        "length" : 5,
        "payload" : "example",
        "type" : "data"
      }
      """
    } decodes: {
      Resource.data(length: 5, payload: "example")
    }
  }

  @Test func decodingNamedParamsWithCustomDiscriminator() throws {
    try assertDecode {
      """
      {
        "kind" : "data",
        "length" : 5,
        "payload" : "example"
      }
      """
    } decodes: {
      ResourceKindDiscriminator.data(length: 5, payload: "example")
    }
  }

  @Test func decodingNamedParamsWithCustomValueKey() throws {
    try assertDecode {
      """
      {
        "body" : {
          "length" : 5,
          "payload" : "example"
        },
        "type" : "data"
      }
      """
    } decodes: {
      ResourceBodyValueKey.data(length: 5, payload: "example")
    }
  }

  @Test func decodingPositionalParams() throws {
    try assertDecode {
      """
      {
        "type" : "check",
        "value" : 100
      }
      """
    } decodes: {
      Payment.check(Check(value: 100))
    }
  }

  @Test func decodingPositionalParamsWithCustomDiscriminator() throws {
    try assertDecode {
      """
      {
        "kind" : "check",
        "value" : 100
      }
      """
    } decodes: {
      PaymentKindDiscriminator.check(Check(value: 100))
    }
  }

  @Test func decodingPositionalParamsWithCustomValueKey() throws {
    try assertDecode {
      """
      {
        "body" : {
          "value" : 100
        },
        "type" : "check"
      }
      """
    } decodes: {
      PaymentBodyValueKey.check(Check(value: 100))
    }
  }
}

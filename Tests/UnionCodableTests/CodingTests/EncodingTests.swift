import Testing

extension UnionCodableTest {
  @Test func encodingNoParams() throws {
    try assertEncode {
      Direction.right
    } encodes: {
      """
      {
        "type" : "right"
      }
      """
    }
  }

  @Test func encodingExternalType() throws {
    try assertEncode {
      ExternalDirection.right
    } encodes: {
      """
      {
        "type" : "right"
      }
      """
    }
  }

  @Test func encodingNoParamsWithCustomDiscriminator() throws {
    try assertEncode {
      DirectionKindDiscriminator.right
    } encodes: {
      """
      {
        "kind" : "right"
      }
      """
    }
  }

  @Test func encodingNamedParams() throws {
    try assertEncode {
      Resource.data(length: 5, payload: "example")
    } encodes: {
      """
      {
        "length" : 5,
        "payload" : "example",
        "type" : "data"
      }
      """
    }
  }

  @Test func encodingNamedParamsWithCustomDiscriminator() throws {
    try assertEncode {
      ResourceKindDiscriminator.data(length: 5, payload: "example")
    } encodes: {
      """
      {
        "kind" : "data",
        "length" : 5,
        "payload" : "example"
      }
      """
    }
  }

  @Test func encodingNamedParamsWithCustomValueKey() throws {
    try assertEncode {
      ResourceBodyValueKey.data(length: 5, payload: "example")
    } encodes: {
      """
      {
        "body" : {
          "length" : 5,
          "payload" : "example"
        },
        "type" : "data"
      }
      """
    }
  }

  @Test func encodingPositionalParams() throws {
    try assertEncode {
      Payment.check(Check(value: 100))
    } encodes: {
      """
      {
        "type" : "check",
        "value" : 100
      }
      """
    }
  }

  @Test func encodingPositionalParamsWithCustomDiscriminator() throws {
    try assertEncode {
      PaymentKindDiscriminator.check(Check(value: 100))
    } encodes: {
      """
      {
        "kind" : "check",
        "value" : 100
      }
      """
    }
  }

  @Test func encodingPositionalParamsWithCustomValueKey() throws {
    try assertEncode {
      PaymentBodyValueKey.check(Check(value: 100))
    } encodes: {
      """
      {
        "body" : {
          "value" : 100
        },
        "type" : "check"
      }
      """
    }
  }
}

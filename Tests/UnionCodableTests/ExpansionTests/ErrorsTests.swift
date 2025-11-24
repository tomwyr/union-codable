import MacroTesting
import Testing

@testable import UnionCodableMacros

extension UnionCodableTest {
  @Test func casesWithDiscriminatorAndParamsConflict() {
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
      ╰─ 🛑 discriminatorCaseParamConflict(caseName: "data")
      enum Resource {
        case loading(progress: Double)
        case data(length: Int, type: String)
        case error
      }
      """
    }
  }

  @Test func casesWithCustomDiscriminatorAndParamsConflict() {
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
      ╰─ 🛑 discriminatorCaseParamConflict(caseName: "data")
      enum Resource {
        case loading(progress: Double)
        case data(length: Int, resource: String)
        case error
      }
      """
    }
  }

  @Test func casesWithDiscriminatorAndValueKeyConflict() {
    assertMacro {
      """
      @UnionCodable(discriminator: "value", layout: .nested())
      enum Resource {
        case loading(progress: Double)
        case data(length: Int, type: String)
        case error
      }
      """
    } diagnostics: {
      """
      @UnionCodable(discriminator: "value", layout: .nested())
      ┬───────────────────────────────────────────────────────
      ╰─ 🛑 discriminatorNestedValueConflict
      enum Resource {
        case loading(progress: Double)
        case data(length: Int, type: String)
        case error
      }
      """
    }
  }

  @Test func casesWithDiscriminatorAndCustomValueKeyConflict() {
    assertMacro {
      """
      @UnionCodable(layout: .nested(key: "type"))
      enum Resource {
        case loading(progress: Double)
        case data(length: Int, resource: String)
        case error
      }
      """
    } diagnostics: {
      """
      @UnionCodable(layout: .nested(key: "type"))
      ┬──────────────────────────────────────────
      ╰─ 🛑 discriminatorNestedValueConflict
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

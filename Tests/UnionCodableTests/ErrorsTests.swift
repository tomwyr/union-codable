import MacroTesting
import Testing

@testable import UnionCodableMacros

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

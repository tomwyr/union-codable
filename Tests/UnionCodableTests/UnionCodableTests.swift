import MacroTesting
import Testing

@testable import UnionCodableMacros

@Suite(.macros([UnionCodableMacro.self]))
struct UnionCodableTest {
    @Test func casesWithNoParams() async throws {
        assertMacro {
            """
            enum Direction {
                case up, down, left, right 
            }
            """
        } expansion: {
            """
            enum Direction {
                case up, down, left, right 
            }
            """
        }
    }
}

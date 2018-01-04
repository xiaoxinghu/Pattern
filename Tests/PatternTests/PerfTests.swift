import XCTest
import Pattern

class PerfTests: XCTestCase {
    
    func testPerformance() {
        let pattern = "(\\w+) (\\d+)$"
        let size = 100_000
        let string = String(repeating: "ABCDE", count: size)
        let number = String(repeating: "12345", count: size)
        let target = "\(string) \(number)"

        let pm = PatternMachine.compile((pattern, 0)).value!
        self.measure {
            _ = pm.matches(target)
        }
    }
    
}

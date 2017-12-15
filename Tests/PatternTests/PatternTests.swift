import XCTest
import Pattern

class PatternTests: XCTestCase {
    func testExample() {
//        let line = "[fn:1] footnote one."
//        let syntax = "\\[fn:(\\w+)\\].*"
//        let nfa = re2nfa(syntax).value!
//        debugPrint("-- \(nfa.captures)")
//        let dfa = nfa.toDFA()
//        for (i, state) in dfa.states.enumerated() {
//            for c in state.captures {
//                debugPrint("\(i): \(c)")
//            }
//        }
//        let pattern = DFABasedPatternMatcher(dfa)
//        let mr = pattern.matches(line)
//        XCTAssert(mr.matches)
//        debugPrint("---------- Captures ----------")
//        for (i, c) in mr.captures.enumerated() {
//            debugPrint(">>> \(i):[\(c)]")
//        }
//        debugPrint("---------- End ----------")

    }
    
    func testPattern() {
        let line = "[fn:1] footnote one."
        let syntax = "\\[fn:(\\w+)\\].*"

        let pattern = compile(syntax).value!
        let mr = pattern.matches(line)
        XCTAssert(mr.matches)
        XCTAssert(mr.matches)
        debugPrint("---------- Captures ----------")
        for (i, c) in mr.captures.enumerated() {
            debugPrint(">>> \(i):[\(c)]")
        }
        debugPrint("---------- End ----------")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}

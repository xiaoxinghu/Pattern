// Generated using Sourcery 0.10.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import XCTest
@testable import PatternTests

extension PatternTests {
  static var allTests = [
    ("testOrgmodePattern", testOrgmodePattern),
    ("testCapture", testCapture),
    ("testMergedMachine", testMergedMachine),
    ("testPatternWithEmojis", testPatternWithEmojis),
    ("testNestedCapture", testNestedCapture),
  ]
}

extension PerfTests {
  static var allTests = [
    ("testPerformance", testPerformance),
  ]
}


XCTMain([
  testCase(PatternTests.allTests),
  testCase(PerfTests.allTests),
])

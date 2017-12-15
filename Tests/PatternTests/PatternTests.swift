import XCTest
@testable import Pattern

func validate(_ pattern: String, matches text: String) -> Bool {
    guard let p = compile(pattern: pattern).value else { return false }
    return p.matches(text).matches
}

func validate(pattern: String, positives: [String] = [], negatives: [String] = [], file: StaticString = #file, line: UInt = #line) {
    for p in positives {
        XCTAssert(validate(pattern, matches: p), "\"\(p)\" should match", file: file, line: line)
    }
    
    for n in negatives {
        XCTAssert(!validate(pattern, matches: n), "\"\(n)\" should not match", file: file, line: line)
    }
}

class PatternTests: XCTestCase {
    
    func testCharExpression() {
        // \s for whitespace
//        XCTAssert(pattern("\\s*$", matchesAll: [ "", "  ", "\t", "  \t "]))
//        XCTAssert(pattern("\\s*$", doesNotMatchAny: [ "a", " \t s " ]))
    }
    
    func testOrgmodePattern() {
        // blank
        validate(pattern: "\\s*$",
                 positives: [ "", "  ", "\t", "  \t "],
                 negatives: [ "s", " \t s " ])

        // headline
        XCTAssert(validate("(\\*+)\\s+.*", matches: "*   a headline"))
        validate(pattern: "(\\*+)\\s+.*",
                 positives: [
                    "** a headline",
                    "**   a headline",
                    "***** a headline",
                    "* a 😀line",
                    "* TODO [#A] a headline     :tag1:tag2:" ],
                 negatives: [
                    "*not a headline",
                    " * not a headline",
                    "*_* not a headline",
                    "not a headline"])
        
        // keyword
        validate(pattern: "\\s*#\\+(\\w+):\\s*(.*)$",
                 positives: [
                   "#+KEY: Value",
                   "#+KEY: Another Value",
                   "#+KEY: value : Value"],
                 negatives: ["#+KEY : Value", "#+KE Y: Value"])
        
        // planning
        validate(pattern: "\\s*(DEADLINE|SCHEDULED|CLOSED):\\s*(.+)$",
                 positives: [
                   "DEADLINE: <blah>",
                   "  DEADLINE: <blah>",
                   " \tDEADLINE: <blah>",
                   " \t SCHEDULED: <blah>"],
                 negatives: ["dEADLINE: <blah>"])
        
        // block begin
        validate(pattern: "\\s*#\\+[Bb][Ee][Gg][Ii][Nn]_(\\w+).*$",
                 positives: [
                   "#+BEGIN_SRC swift",
                   " #+BEGIN_SRC swift",
                   "#+begin_src swift",
                   "#+begin_example",
                   "#+begin_ex😀mple",
                   "#+begin_src swift :tangle code.swift"],
                 negatives: ["#+begi😀n_src swift"])
        
        // block end
        validate(pattern: "\\s*#\\+[Ee][Nn][Dd]_([^ ]+)$",
                 positives: [
                   "#+END_SRC",
                   "  #+END_SRC",
                   "#+end_src",
                   "#+end_SRC",
                   "#+end_S😀RC"],
                 negatives: ["#+end_SRC ", "#+end_src param"])
        
        // horizontal rule
        validate(pattern: "\\s*-----+\\s*$",
                 positives: [
                   "-----",
                   "------",
                   "--------",
                   "  -----",
                   "-----   ",
                   "  -----   ",
                   "  -----  \t "],
                 negatives: [
                   "----",
                   "- ----",
                   "-----a",
                   "_-----",
                   "-----    a"])
        
        // comment
        validate(pattern: "\\s*#\\s.*",
                 positives: [
                   "# a comment",
                   "# ",
                   "# a comment😯",
                   " # a comment",
                   "  \t  # a comment",
                   "#   a comment",
                   "#    \t a comment"],
                 negatives: ["#not a comment", "  #not a comment"])
        
        // list item
        validate(pattern: "\\s*([-+]|\\d+[.)])\\s+.*",
                 positives: [
                   "- item one",
                   // "* item one", TODO: conflict with headline?
                   "+ item one",
                   "1. item one",
                   "12. item one",
                   "123) item one"],
                 negatives: [
                   "-not item",
                   "1.not item",
                   "8)not item",
                   "8a) not item"])
        
        // footnote
        validate(pattern: "\\[fn:(\\w+)\\].*",
                 positives: [
                   "[fn:1]: a footnote",
                   "[fn:word]: a footnote",
                   "[fn:word_]: a footnote",
                   "[fn:wor1d_]: a footnote"],
                 negatives: [
                   " [fn:1]: not a footnote",
                   "[[fn:1]: not a footnote",
                   "\t[fn:1]: not a footnote"])
        
        // table separator
        validate(pattern: "\\s*\\|-",
                 positives: [
                   "|----+---+----|",
                   "|--=-+---+----|",
                   "  |----+---+----|",
                   "|----+---+----",
                   "|---",
                   "|-"],
                 negatives: ["----+---+----|"])
        
        // table row
        validate(pattern: "\\s*\\|(\\s*.+\\|)+\\s*$",
                 positives: [
                   "| hello | world | y'all |",
                   "   | hello | world | y'all |",
                   "|    hello |  world   |y'all |"],
                 negatives: [" hello | world | y'all |", "|+"])
        
        // drawer begin
        validate(pattern: "\\s*:(\\w+):\\s*$",
                 positives: [
                   ":PROPERTIES:",
                   "  :properties:",
                   "  :properties:  ",
                   "  :prop_erties:  "],
                 negatives: [
                   "PROPERTIES:",
                   ":PROPERTIES",
                   ":PR OPERTIES:"])
        
        // drawer end
        validate(pattern: "\\s*:(END|end):\\s*",
                 positives: [":END:", "  :end:", "  :end:  ", "  :end:  "],
                 negatives: [":ENd:", "END:", ":END", ":ENDed"])
    }


    static var allTests = [
        ("testCharExpression", testCharExpression),
        ("testOrgmodePattern", testOrgmodePattern),
    ]
}

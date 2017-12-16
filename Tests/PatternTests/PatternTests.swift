import XCTest
import Pattern

func match(_ pattern: String, against text: String) -> MatchResult<String>? {
    guard let p = PatternMachine.compile((pattern, pattern)).value else { return nil }
    return p.matches(text)
}

func validate(pattern: String, positives: [String] = [], negatives: [String] = [], file: StaticString = #file, line: UInt = #line) {
    for p in positives {
        let mr = match(pattern, against: p)!
        XCTAssert(mr.matches, "\"\(p)\" should match", file: file, line: line)
        XCTAssertEqual(mr.data, pattern, file: file, line: line)
    }
    
    for n in negatives {
        let mr = match(pattern, against: n)!
        XCTAssert(!mr.matches, "\"\(n)\" should not match", file: file, line: line)
        XCTAssertNil(mr.data, file: file, line: line)
    }
}

enum OrgSyntax: String {
    case headline = "(\\*+)\\s+.*"
    case keyword = "\\s*#\\+(\\w+):\\s*(.*)$"
    case aKeyword = "\\s*#\\+(CAPTION|HEADER|NAME|PLOT|RESULTS|ATTR_BACKEND):\\s*(.*)$"
    case blank = "\\s*$"
    case planning = "\\s*(DEADLINE|SCHEDULED|CLOSED):\\s*(.+)$"
    case blockBegin = "\\s*#\\+[Bb][Ee][Gg][Ii][Nn]_(\\w+).*$"
    case blockEnd = "\\s*#\\+[Ee][Nn][Dd]_([^ ]+)$"
    case horizontalRule = "\\s*-----+\\s*$"
    // TODO: implement repeat
    //    case horizontalRule = "\\s*-{5,}\\s*$"
    case comment = "\\s*#\\s.*"
    case listItem = "\\s*([-+]|\\d+[.)])\\s+.*"
    case footnote = "\\[fn:(\\w+)\\].*"
    case tableSeparator = "\\s*\\|-"
    case tableRow = "\\s*\\|(\\s*.+\\|)+\\s*$"
    case drawerBegin = "\\s*:(\\w+):\\s*$"
    case drawerEnd = "\\s*:(END|end):\\s*"
}

class PatternTests: XCTestCase {
    
    func testOrgmodePattern() {
        // blank
        validate(pattern: OrgSyntax.blank.rawValue,
                 positives: [ "", "  ", "\t", "  \t "],
                 negatives: [ "s", " \t s " ])

        // headline
        validate(pattern: OrgSyntax.headline.rawValue,
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
        validate(pattern: OrgSyntax.keyword.rawValue,
                 positives: [
                   "#+KEY: Value",
                   "#+KEY: Another Value",
                   "#+KEY: value : Value"],
                 negatives: ["#+KEY : Value", "#+KE Y: Value"])
        
        // planning
        validate(pattern: OrgSyntax.planning.rawValue,
                 positives: [
                   "DEADLINE: <blah>",
                   "  DEADLINE: <blah>",
                   " \tDEADLINE: <blah>",
                   " \t SCHEDULED: <blah>"],
                 negatives: ["dEADLINE: <blah>"])
        
        // block begin
        validate(pattern: OrgSyntax.blockBegin.rawValue,
                 positives: [
                   "#+BEGIN_SRC swift",
                   " #+BEGIN_SRC swift",
                   "#+begin_src swift",
                   "#+begin_example",
                   "#+begin_ex😀mple",
                   "#+begin_src swift :tangle code.swift"],
                 negatives: ["#+begi😀n_src swift"])
        
        // block end
        validate(pattern: OrgSyntax.blockEnd.rawValue,
                 positives: [
                   "#+END_SRC",
                   "  #+END_SRC",
                   "#+end_src",
                   "#+end_SRC",
                   "#+end_S😀RC"],
                 negatives: ["#+end_SRC ", "#+end_src param"])
        
        // horizontal rule
        validate(pattern: OrgSyntax.horizontalRule.rawValue,
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
        validate(pattern: OrgSyntax.comment.rawValue,
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
        validate(pattern: OrgSyntax.listItem.rawValue,
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
        validate(pattern: OrgSyntax.footnote.rawValue,
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
        validate(pattern: OrgSyntax.tableSeparator.rawValue,
                 positives: [
                   "|----+---+----|",
                   "|--=-+---+----|",
                   "  |----+---+----|",
                   "|----+---+----",
                   "|---",
                   "|-"],
                 negatives: ["----+---+----|"])
        
        // table row
        validate(pattern: OrgSyntax.tableRow.rawValue,
                 positives: [
                   "| hello | world | y'all |",
                   "   | hello | world | y'all |",
                   "|    hello |  world   |y'all |"],
                 negatives: [" hello | world | y'all |", "|+"])
        
        // drawer begin
        validate(pattern: OrgSyntax.drawerBegin.rawValue,
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
        validate(pattern: OrgSyntax.drawerEnd.rawValue,
                 positives: [":END:", "  :end:", "  :end:  ", "  :end:  "],
                 negatives: [":ENd:", "END:", ":END", ":ENDed"])
    }
    
    func testCapture() {
        let pattern = "(\\d+)-(\\d+)-(\\d+)$"
        
        let p = PatternMachine.compile((pattern, pattern)).value!
        let result = p.matches("2017-12-16")
        XCTAssert(result.matches)
        XCTAssertEqual(result.captures.count, 3)
        XCTAssertEqual(result.captures[0], "2017")
        XCTAssertEqual(result.captures[1], "12")
        XCTAssertEqual(result.captures[2], "16")
    }
    
    func testMergedMachine() {
        let syntax = [
            (OrgSyntax.headline.rawValue, "headline"),
            (OrgSyntax.keyword.rawValue, "keyword"),
            ]
        let p = PatternMachine.compile(syntax).value!
        XCTAssert(p.matches("* headline").matches)
        XCTAssert(p.matches("#+TITLE: hello").matches)
        XCTAssert(!p.matches("").matches)
        XCTAssert(!p.matches("#+BEGIN_SRC swift").matches)
    }
    
    static var allTests = [
        ("testOrgmodePattern", testOrgmodePattern),
    ]
}

import Foundation

public enum PError: Error {
    case unexpectedToken(String)
    case cannotFindToken(String)
    case other(Error)
    
    case illegalRegexSyntax(String)
    case regex2nfa(String)
    case tokenize(String)
    case parse(String)
}


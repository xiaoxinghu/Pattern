//
//  Errors.swift
//  Pattern
//
//  Created by xhu on 14/12/17.
//

import Foundation

public enum OKError: Error {
    case unexpectedToken(String)
    case cannotFindToken(String)
    case other(Error)
    
    case illegalRegexSyntax(String)
    case regex2nfa(String)
    case tokenize(String)
    case parse(String)
}


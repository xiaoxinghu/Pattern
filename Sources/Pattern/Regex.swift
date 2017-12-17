//
//  Regex.swift
//  OrgKit
//
//  Created by xhu on 21/07/17.
//

import Foundation
import FuncKit
import Automata

typealias RegexDFA = DFA<UInt32>
typealias RegexNFA = NFA<UInt32>

enum RegexToken {
    
    case lParen
    case rParen
    case lBracket
    case rBracket
    case star
    case alt
    case concat
    case plus
    case qmark
    case dot
    case escape
    case eol
    case negate
    case literal(UInt32)
    case capture
    
    static var symbols: [RegexToken] {
        return [.lParen, .rParen, .lBracket, .rBracket, .star, .alt, .plus, qmark, .dot, .escape, .eol, .negate]
    }
    
    var char: Character {
        switch self {
        case .lParen:
            return "("
        case .rParen:
            return ")"
        case .lBracket:
            return "["
        case .rBracket:
            return "]"
        case .star:
            return "*"
        case .alt:
            return "|"
        case .plus:
            return "+"
        case .qmark:
            return "?"
        case .dot:
            return "."
        case .escape:
            return "\\"
        case .eol:
            return "$"
        case .negate:
            return "^"
        default: fatalError()
        }
    }
}

extension Character {
    func isNot(_ symbols: RegexToken...) -> Bool {
        return !symbols.contains { self.is($0) }
    }
    
    func `is`(_ symbol: RegexToken) -> Bool {
        return self == symbol.char
    }
    
    func isOneOf(_ symbols: RegexToken...) -> Bool {
        return symbols.contains { self.is($0) }
    }
    
    var regexToken: RegexToken {
        if let s = RegexToken.symbols.first(where: { self.is($0) }) {
            return s
        }
        return .literal(self.unicodeScalars.first!.value)
    }
}

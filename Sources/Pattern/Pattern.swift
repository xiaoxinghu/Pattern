//
//  Pattern.swift
//  OrgKit
//
//  Created by xhu on 30/07/17.
//

import Foundation
import FuncKit

public struct MatchResult<T> {
    public var string: String = ""
    public var matches: Bool = false
    public var captures: [String] = []
    public var data: T? = nil
}

public protocol Pattern {
    associatedtype DataType
    func matches(_ string: String) -> MatchResult<DataType>
}

private func nfa2dfa<T>(_ nfa: RegexNFA<T>) -> RegexDFA<T> {
    return nfa.toDFA()
}

extension Regex {
    public static func compile(pattern: String, attachment: T) -> Result<Regex<T>> {
        return Regex.init <^> (nfa2dfa <^> re2nfa(pattern, attachment: attachment))
    }
}

public struct Regex<T> : Pattern {
    public typealias DataType = T
    
    let dfa: RegexDFA<T>
    
    init(_ _dfa: RegexDFA<T>) {
        dfa = _dfa
    }

    
    public func matches(_ string: String) -> MatchResult<T> {
        var state = dfa.initial
        var result = MatchResult<T>()
        result.string = string
        for c in string.unicodeScalars {
            if let next = findNext(from: state, with: c) {
                if let group = dfa.states[state].captures[next] {
                    while result.captures.count <= group {
                        result.captures.append("")
                    }
                    result.captures[group].append(Character(c))
                }
                
                if dfa.states[next].isEnd {
                    result.matches = true
                    result.data = dfa.states[next].data
                    return result
                }
                state = next
                continue
            }
            return result
        }
        if let eof = dfa.states[state].transitions[CharacterExpression.eol.rawValue] {
            if dfa.states[eof].isEnd {
                result.matches = true
                result.data = dfa.states[eof].data
                return result
            }
        }
        return result
    }
    
    func findNext(from state: Int, with input: Unicode.Scalar) -> Int? {
        let state = dfa.states[state]
        if let dest = state.transitions[input.value] { return dest }
        
        //        let specials: [CharacterExpression] = [.d, .w, .any]
        //        for ce in specials {
        //            if let dest = state.transitions[ce.rawValue], ce.match(input) {
        //                return dest
        //            }
        //        }
        
        if let dest = state.transitions[CharacterExpression.d.rawValue],
            CharacterExpression.d.match(input) {
            return dest
        }
        if let dest = state.transitions[CharacterExpression.w.rawValue],
            CharacterExpression.w.match(input) {
            return dest
        }
        if let dest = state.transitions[CharacterExpression.any.rawValue],
            CharacterExpression.any.match(input) {
            return dest
        }
        
        return nil
    }
    
}

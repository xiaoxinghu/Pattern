//
//  Pattern.swift
//  OrgKit
//
//  Created by xhu on 30/07/17.
//

import Foundation
import FuncKit

public struct MatchResult {
    public var string: String = ""
    public var matches: Bool = false
    public var captures: [String] = []
}

public protocol Pattern {
    func matches(_ string: String) -> MatchResult
}

private func nfa2dfa(_ nfa: RegexNFA) -> RegexDFA {
    return nfa.toDFA()
}

public func compile(pattern: String) -> Result<Pattern> {
    return DFABasedPattern.init <^> (nfa2dfa <^> re2nfa(pattern))
}

struct DFABasedPattern : Pattern {
    
    let dfa: RegexDFA
    
    init(_ _dfa: RegexDFA) {
        dfa = _dfa
    }

    
    public func matches(_ string: String) -> MatchResult {
        var state = dfa.initial
        var result = MatchResult()
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

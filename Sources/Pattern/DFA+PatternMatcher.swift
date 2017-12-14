//
//  DFA+PatternMatcher.swift
//  Pattern
//
//  Created by xhu on 14/12/17.
//

import Foundation
import Automata

extension DFA where InputType == UInt32 {
    public func matches(_ string: String) -> MatchResult {
        var state = initial
        var result = MatchResult()
        result.string = string
        for c in string.unicodeScalars {
            if let next = findNext(from: state, with: c) {
                if let group = states[state].captures[next] {
                    while result.captures.count <= group {
                        result.captures.append("")
                    }
                    result.captures[group].append(Character(c))
                }
                
                if states[next].isEnd {
                    result.matches = true
                    return result
                }
                state = next
                continue
            }
            return result
        }
        if let eof = states[state].transitions[CharacterExpression.eol.rawValue] {
            if states[eof].isEnd {
                result.matches = true
                return result
            }
        }
        return result
    }
    
    func findNext(from state: Int, with input: Unicode.Scalar) -> Int? {
        let state = states[state]
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
        
        //        if let dest = state.transitions[CharacterExpression.any.rawValue] { return dest }
        return nil
    }
}



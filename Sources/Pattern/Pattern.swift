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

public struct PatternMachine<T> {
    
    var dfa: RegexDFA<T>
    
    let nfas: [RegexNFA<T>]
    
    init(_ _nfas: RegexNFA<T>...) {
        nfas = _nfas
        dfa = RegexNFA.merge(nfas).toDFA()
    }
    
    init(_ _nfas: [RegexNFA<T>]) {
        nfas = _nfas
        dfa = RegexNFA.merge(nfas).toDFA()
    }
    
    public mutating func compile() {
        dfa = RegexNFA.merge(nfas).toDFA()
    }

}

private func _append<T>(all: [RegexNFA<T>], other: RegexNFA<T>) -> [RegexNFA<T>] {
    return all + [other]
}

extension PatternMachine {
    public static func compile(_ branches: (String, T)...) -> Result<PatternMachine<T>> {
        return _compile(branches)
    }
    
    public static func compile(_ branches: [(String, T)]) -> Result<PatternMachine<T>> {
        return _compile(branches)
    }
}

private func _compile<T>(_ branches: [(String, T)]) -> Result<PatternMachine<T>> {
    return branches.map(re2nfa).reduce(.success([])) { all, current in
        return curry(_append) <^> all <*> current
        }.map { PatternMachine($0) }
}

extension PatternMachine : Pattern {
    public typealias DataType = T
    
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
        
        // TODO: code like this has significant impact on perf, because for in loop sucks
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

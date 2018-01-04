import Foundation
import FuncKit

public struct MatchResult {
    public var string: String = ""
    public var matches: Bool = false
    public var captures: [String] = []
    public var traceId: Int = -1
}

public protocol Pattern {
    func matches(_ string: String) -> MatchResult
}

public struct PatternMachine {
    
    var dfa: RegexDFA
    
    let nfas: [RegexNFA]
    
    init(_ _nfas: RegexNFA...) {
        nfas = _nfas
        dfa = RegexNFA.merge(nfas).toDFA()
    }
    
    init(_ _nfas: [RegexNFA]) {
        nfas = _nfas
        dfa = RegexNFA.merge(nfas).toDFA()
    }
    
    public mutating func compile() {
        dfa = RegexNFA.merge(nfas).toDFA()
    }

}

private func _append(all: [RegexNFA], other: RegexNFA) -> [RegexNFA] {
    return all + [other]
}

extension PatternMachine {
    public static func compile(_ branches: (String, Int)...) -> Result<PatternMachine> {
        return _compile(branches)
    }
    
    public static func compile(_ branches: [(String, Int)]) -> Result<PatternMachine> {
        return _compile(branches)
    }
}

private func _compile(_ branches: [(String, Int)]) -> Result<PatternMachine> {
    return branches.map(re2nfa).reduce(.success([])) { all, current in
        return curry(_append) <^> all <*> current
        }.map { PatternMachine($0) }
}

extension PatternMachine : Pattern {
    
    public func matches(_ string: String) -> MatchResult {
        var state = dfa.initial
        var result = MatchResult()
        result.string = string
        
        var iterator = string.unicodeScalars.makeIterator()
        var captureDone = false
        while let c = iterator.next() {
            if let next = findNext(from: state, with: c) {
                if let group = dfa.states[state].captures[next] {
                    captureDone = false
                    while result.captures.count <= group {
                        result.captures.append("")
                    }
                    result.captures[group].append(Character(c))
                } else if result.matches && captureDone {
                    return result
                } else {
                    captureDone = true
                }
                
                if dfa.states[next].isEnd {
                    result.matches = true
                    result.traceId = dfa.states[next].traceId
                }
                state = next
                continue
            }
            return result
        }
        if let eof = dfa.states[state].transitions[CharacterExpression.eol.rawValue] {
            if dfa.states[eof].isEnd {
                result.matches = true
                result.traceId = dfa.states[eof].traceId
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

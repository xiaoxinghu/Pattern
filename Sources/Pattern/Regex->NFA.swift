//
//  Regex+NFA.swift
//  OrgKit
//
//  Created by xhu on 20/07/17.
//

import Foundation
import FuncKit
import Automata

func regexTokens2nfa(_ tokens: [RegexToken]) -> Result<RegexNFA> {
    var stack = [RegexNFA]()
    for t in tokens {
        switch t {
        case .concat:
            assert(stack.count >= 2)
            let n2 = stack.popLast()!
            let n1 = stack.popLast()!
            stack.append(n1.concat(n2))
        case .alt:
            assert(stack.count >= 2)
            let n1 = stack.popLast()!
            let n2 = stack.popLast()!
            stack.append(n1.alt(n2))
        case .plus:
            assert(stack.count >= 1)
            let n = stack.popLast()!
            stack.append(n.plus())
        case .star:
            assert(stack.count >= 1)
            let n = stack.popLast()!
            stack.append(n.star())
        case .qmark:
            assert(stack.count >= 1)
            let n = stack.popLast()!
            stack.append(n.qmark())
        case .negate:
            assert(stack.count >= 1)
            let n = stack.popLast()!
            stack.append(n.negate())
        case .literal(let char):
            stack.append(NFA(char))
        case .dot:
            stack.append(NFA(CharacterExpression.any.rawValue))
        case .capture:
            assert(stack.count >= 1)
            let n = stack.popLast()!
            n.captures.append(n.edges)
            stack.append(n)
        default: fatalError()
        }
    }
    
    guard stack.count == 1 else {
        return .failure(PError.regex2nfa("Expect to have one nfa in the stack now. But got \(stack.count)"))
    }
    return .success(stack.popLast()!)
}

var re2nfa: ((String) -> Result<RegexNFA>) = re2post |> regexTokens2nfa

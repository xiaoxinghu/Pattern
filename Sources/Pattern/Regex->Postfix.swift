//
//  Regex+Postfix.swift
//  OrgKit
//
//  Created by Xiaoxing Hu on 17/07/17.
//
//

import Foundation
import FuncKit
import Automata

private struct RegexSyntax {
    var infix: String
    var postfix: [RegexToken]
    
    init(_ _pattern: String) {
        infix = _pattern
        postfix = []
    }
    
    var peek: Character? {
        return infix.first
    }
    
}

private func consume(char: Character, syntax: RegexSyntax) -> Result<RegexSyntax> {
    var syntax = syntax
    if let c = syntax.infix.first, c == char {
        syntax.infix = String(syntax.infix.dropFirst(1))
        return .success(syntax)
    } else {
        return .failure(PError.illegalRegexSyntax("expecting char: \(char), but got: \(String(describing: syntax.infix.first))"))
    }
}

private func consume(symbol: RegexToken, syntax: RegexSyntax) -> Result<RegexSyntax> {
    return consume(char: symbol.char, syntax: syntax)
}

private func next(_ syntax: RegexSyntax) -> Result<(Character, RegexSyntax)> {
    if let c = syntax.peek {
        return consume(char: c, syntax: syntax).map { (c, $0) }
    }
    return .failure(PError.illegalRegexSyntax("Expecting char here."))
}

private func append(token: RegexToken, to syntax: RegexSyntax) -> Result<RegexSyntax> {
    var syntax = syntax
    syntax.postfix.append(token)
    return .success(syntax)
}

func re2post(_ pattern: String) -> Result<[RegexToken]> {
    return exp(RegexSyntax(pattern)).flatMap {
        return .success($0.postfix)
    }
}

private func exp(_ syntax: RegexSyntax) -> Result<RegexSyntax> {
    return term(syntax).flatMap { syntax in
        guard let c = syntax.peek else { return .success(syntax) }
        if c.is(.alt) {
            let f = curry(consume)(c) |> exp |> curry(append)(.alt)
            return f(syntax)
        }
        return .success(syntax)
    }
}

private func term(_ syntax: RegexSyntax) -> Result<RegexSyntax> {
    return factor(syntax).flatMap { syntax in
        guard let c = syntax.peek else { return .success(syntax) }
        if c.isNot(.rParen, .alt) {
            return (term |> curry(append)(.concat))(syntax)
        }
        return .success(syntax)
    }
}

private func factor(_ syntax: RegexSyntax) -> Result<RegexSyntax> {
    return primary(syntax).flatMap { syntax in
        guard let c = syntax.peek else { return .success(syntax) }
        if c.isOneOf(.star, .plus, .qmark) {
            return (curry(append)(c.regexToken) |> curry(consume)(c))(syntax)
        }
        return .success(syntax)
    }
}

private var processCharClass = curry(consume)(.lBracket) |> handleCharSet |> curry(consume)(.rBracket)

private func handleCharSet(_ syntax: RegexSyntax) -> Result<RegexSyntax> {
    var negated = false
    guard let c = syntax.peek else {
        return .failure(PError.illegalRegexSyntax("Expecting char after ["))
    }
    var f: (RegexSyntax) -> Result<RegexSyntax> = { .success($0) }
    // check if is negated
    if c.is(.negate) {
        f = f |> curry(consume)(c)
        negated = true
    }
    
    f = f |> replaceRangeWithLiteral |> charSet
    
    return f(syntax).flatMap {
        if negated {
            return append(token: .negate, to: $0)
        }
        return .success($0)
    }
}

private func replaceRangeWithLiteral(_ syntax: RegexSyntax) -> Result<RegexSyntax> {
    var syntax = syntax
    var infix = syntax.infix
    
    guard let end = infix.index(of: "]") else {
        return .failure(PError.illegalRegexSyntax("Cannot find closing ]"))
    }
    let theCharSet = String(infix[infix.startIndex..<end])
    
    return replaceRangeWithLiteral(theCharSet).map { theCharSet in
        infix.replaceSubrange(infix.startIndex..<end, with: theCharSet)
        syntax.infix = infix
        return syntax
    }
}

func replaceRangeWithLiteral(_ string: String) -> Result<String> {
    var chars: [Character] = []
    var rangeFrom: Character? = nil
    for c in string {
        if c == "-" && !chars.isEmpty {
            rangeFrom = chars.removeLast()
            continue
        }
        
        if let _rangeFrom = rangeFrom {
            guard let from = _rangeFrom.asciiValue, let to = c.asciiValue else {
                return .failure(PError.illegalRegexSyntax("Illegal Character for range"))
            }
            if from > to {
                return .failure(PError.illegalRegexSyntax("Cannot form range with upperBound < lowerBound"))
            }
            let range = Array(from...to).map { Character(Unicode.Scalar($0)!) }
            chars += range
            rangeFrom = nil
            continue
        }
        
        chars.append(c)
    }
    
    if let from = rangeFrom {
        chars += [from, "-"]
    }
    
    return .success(String(chars))
}

private func charSet(_ syntax: RegexSyntax) -> Result<RegexSyntax> {
    return literal(syntax).flatMap { syntax in
        guard let c = syntax.peek else { return .success(syntax) }
        if c.isNot(.rBracket) {
            return (charSet |> curry(append)(.alt))(syntax)
        }
        return .success(syntax)
    }
}

private func literal(_ syntax: RegexSyntax) -> Result<RegexSyntax> {
    return next(syntax).flatMap { c, syntax in
        return append(token: .literal(c.unicodeScalars.first!.value), to: syntax)
    }
}

private func handleEscape(_ syntax: RegexSyntax) -> Result<RegexSyntax> {
    return next(syntax).flatMap { (n, syntax) in
        switch n {
        case "s":
            var syntax = syntax
            syntax.infix = "[ \t]" + syntax.infix
            return processCharClass(syntax)
        case "d":
            return append(token: .literal(CharacterExpression.d.rawValue), to: syntax)
        case "w":
            return append(token: .literal(CharacterExpression.w.rawValue), to: syntax)
        default:
            return append(token: .literal(n.unicodeScalars.first!.value), to: syntax)
        }
    }

}

private func primary(_ syntax: RegexSyntax) -> Result<RegexSyntax> {
    guard let c = syntax.peek else { return .success(syntax) }
    
    switch c.regexToken {
    case .lParen: // handle ( exp )
        return (curry(consume)(.lParen) |> exp |> curry(consume)(.rParen) |> curry(append)(.capture))(syntax)
    case .escape: // \ char
        return (curry(consume)(.escape) |> handleEscape)(syntax)
    case .dot:
        return (curry(append)(.dot) |> curry(consume)(c))(syntax)
    case .lBracket:
        return processCharClass(syntax)
    case .literal(let char):
        return (curry(append)(.literal(char)) |> curry(consume)(c))(syntax)
    case .eol:
        return (curry(append)(.literal(CharacterExpression.eol.rawValue)) |> curry(consume)(c))(syntax)
    default:
        return .failure(PError.illegalRegexSyntax("Don't know how to process '\(c)' at this stage."))
    }
}

extension Character {
    var asciiValue: UInt32? {
        return String(self).unicodeScalars.filter{$0.isASCII}.first?.value
    }
}


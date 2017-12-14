//
//  Pattern.swift
//  OrgKit
//
//  Created by xhu on 30/07/17.
//

import Foundation

public struct MatchResult {
    var string: String = ""
    var matches: Bool = false
    var captures: [String] = []
}

protocol PatternMatcher {
    func matches(_ string: String) -> MatchResult
}

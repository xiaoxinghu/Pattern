import Foundation
import Automata

extension NFA {
    func plus() -> NFA {
        let newInitial = newState()
        let newFinal = newState()
        epsilon(from: newInitial, to: initial)
        finals.forEach {
            epsilon(from: $0, to: newFinal)
            epsilon(from: $0, to: initial)
        }
        initial = newInitial
        finals = [newFinal]
        return self
    }
    
    func star() -> NFA {
        _ = plus()
        finals.forEach {
            epsilon(from: initial, to: $0)
        }
        return self
    }
    
    func concat(_ other: NFA) -> NFA {
        other.shift(offset: states.count)
        states.append(contentsOf: other.states)
        finals.forEach {
            epsilon(from: $0, to: other.initial)
        }
        captures.append(contentsOf: other.captures)
        finals = other.finals
        return self
    }
    
    func alt(_ other: NFA) -> NFA {
        other.shift(offset: states.count)
        states.append(contentsOf: other.states)
        let newInitial = newState()
        let newFinal = newState()
        
        epsilon(from: newInitial, to: initial)
        epsilon(from: newInitial, to: other.initial)
        finals.forEach {
            epsilon(from: $0, to: newFinal)
        }
        other.finals.forEach {
            epsilon(from: $0, to: newFinal)
        }
        
        
        initial = newInitial
        finals = [newFinal]
        return self
    }
    
    func qmark() -> NFA {
        finals.forEach {
            epsilon(from: initial, to: $0)
        }
        return self
    }
    
    var edges: [Edge<InputType>] {
        var all = [Edge<InputType>]()
        for (i, s) in states.enumerated() {
            for (input, dests) in s.transitions {
                all.append(contentsOf: dests.map { Edge(from: i, to: $0, input: input) })
            }
        }
        return all
    }
}

extension NFA where InputType == UInt32 {
    func negate() -> NFA {
        let newFinal = newState()
        transition(from: initial, to: newFinal, with: CharacterExpression.any.rawValue)
        finals = [newFinal]
        return self
    }
}


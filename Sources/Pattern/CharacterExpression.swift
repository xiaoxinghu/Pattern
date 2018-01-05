import Foundation

enum CharacterExpression: UInt32 {
    case any = 0x110000
    case d
    case w
    case eol
}

extension CharacterExpression {
    
    static func isD(_ c: Unicode.Scalar) -> Bool {
        let n = Int(c.value)
        return n >= 48 && n <= 57
    }
    
    static func isW(_ c: Unicode.Scalar) -> Bool {
        let n = Int(c.value)
        switch n {
        case 97...122, 65...90, 48...57, 95:
            return true
        default: return false
        }
    }
}

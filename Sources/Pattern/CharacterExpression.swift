import Foundation

enum CharacterExpression: UInt32 {
    case any = 0x110000
    case d
    case w
    case eol
}

extension CharacterExpression {
    func match(_ c: Unicode.Scalar) -> Bool {
        switch self {
        case .any:
            return true
        case .d:
            let n = Int(c.value)
            return n >= 48 && n <= 57
        case .w:
            let n = Int(c.value)
            switch n {
            case 97...122, 65...90, 48...57, 95:
                return true
            default: return false
            }
        default:
            return c.value == self.rawValue
        }
    }
}

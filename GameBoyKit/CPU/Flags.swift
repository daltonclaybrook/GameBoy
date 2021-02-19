public struct Flags: OptionSet {
    public let rawValue: UInt8

    public static let fullCarry = Flags(rawValue: 1 << 4)
    public static let halfCarry = Flags(rawValue: 1 << 5)
    public static let subtract = Flags(rawValue: 1 << 6)
    public static let zero = Flags(rawValue: 1 << 7)

    public init(rawValue: UInt8) {
        // The lower nibble must always be zero
        self.rawValue = rawValue & 0xf0
    }
}

extension Flags: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = UInt8

    public init(integerLiteral value: UInt8) {
        self.init(rawValue: value)
    }
}

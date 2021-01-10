public struct Interrupts: OptionSet {
    public let rawValue: UInt8

    public static let vBlank = Interrupts(rawValue: 1 << 0)
    public static let lcdStat = Interrupts(rawValue: 1 << 1)
    public static let timer = Interrupts(rawValue: 1 << 2)
    public static let serial = Interrupts(rawValue: 1 << 3)
    public static let joypad = Interrupts(rawValue: 1 << 4)

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
}

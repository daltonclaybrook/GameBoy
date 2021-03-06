public typealias MemoryMap = ClosedRange<Address>

extension ClosedRange where Bound == Address {
    /// The cartridge ROM
    public static let ROM: ClosedRange<Address> = 0x0000...0x7fff
    /// Video RAM
    public static let VRAM: ClosedRange<Address> = 0x8000...0x9fff
    /// External save RAM, aka "SRAM"
    public static let externalRAM: ClosedRange<Address> = 0xa000...0xbfff
    /// Work RAM
    public static let WRAM: ClosedRange<Address> = 0xc000...0xdfff
    /// Mirror of WRAM. Typically not used.
    public static let ECHO: ClosedRange<Address> = 0xe000...0xfdff
    /// Object Attribute Memory, aka Sprite Attribute Table
    public static let OAM: ClosedRange<Address> = 0xfe00...0xfe9f
    /// Not usable
    public static let unusable: ClosedRange<Address> = 0xfea0...0xfeff
    /// Input/output devices, e.g. joypad, sound controller, etc
    public static let IO: ClosedRange<Address> = 0xff00...0xff7f
    /// High RAM
    public static let HRAM: ClosedRange<Address> = 0xff80...0xfffe
    /// Single register for enabling the various interrupts
    public static let interruptEnable: Address = 0xffff
}

extension Array where Element == Byte {
    func read(address: Address) -> Byte {
        return self[Int(address)]
    }

    func read(address: Address, in range: ClosedRange<Address>) -> Byte {
        return self[Int(address - range.lowerBound)]
    }

    /// Used when reading from a large ROM
    func read(address: UInt32) -> Byte {
        return self[Int(truncatingIfNeeded: address)]
    }

    mutating func write(byte: Byte, to address: Address) {
        self[Int(address)] = byte
    }

    mutating func write(byte: Byte, to address: Address, in range: ClosedRange<Address>) {
        self[Int(address - range.lowerBound)] = byte
    }

    /// Used when writing to a large external RAM
    mutating func write(byte: Byte, to address: UInt32) {
        self[Int(address)] = byte
    }
}

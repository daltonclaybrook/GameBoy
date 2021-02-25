public final class MMU: MemoryAddressable {
    public var mask: MemoryMasking?
    public var isDMATransferActive = false

    private(set) var cartridge: CartridgeType?
    private let vram: VRAM
    private let wram: WRAM
    private let oam: OAM
    private let io: IO
    private let hram: HRAM
    /// Does this make sense as a plain field on the MMU,
    /// or should it have an object like the other regions?
    /// Maybe pull `interruptFlags` out of `IO` and create
    /// an `Interrupts` type?
    private(set) var interruptEnable: Interrupts = []

    init(vram: VRAM, wram: WRAM, oam: OAM, io: IO, hram: HRAM) {
        self.vram = vram
        self.wram = wram
        self.oam = oam
        self.io = io
        self.hram = hram
        self.vram.dmaUtility?.memory = self
    }

    public func load(cartridge: CartridgeType) {
        self.cartridge = cartridge
    }

    public func read(address: Address) -> Byte {
        read(address: address, privileged: false)
    }

    /// Passing true for `privileged` allows reading from the MMU even during a DMA transfer
    public func read(address: Address, privileged: Bool) -> Byte {
        if let mask = mask, mask.isAddressMasked(address) {
            return mask.read(address: address)
        }

        if isDMATransferActive && !privileged && (0x00..<MemoryMap.OAM.lowerBound).contains(address) {
            // ROM and RAM is inaccessible by the CPU during DMA transfer
            return 0xff
        }

        switch address {
        case MemoryMap.ROM:
            return cartridge?.read(address: address) ?? 0
        case MemoryMap.VRAM:
            return vram.read(address: address)
        case MemoryMap.externalRAM:
            return cartridge?.read(address: address) ?? 0
        case MemoryMap.WRAM:
            return wram.read(address: address)
        case MemoryMap.ECHO: // (Same as C000-DDFF)
            return wram.read(address: address - 0x2000)
        case MemoryMap.OAM:
            return oam.read(address: address)
        case MemoryMap.unusable:
            // This region of memory is unusable
            return 0xff
        case MemoryMap.IO:
            return io.read(address: address)
        case MemoryMap.HRAM:
            return hram.read(address: address)
        case MemoryMap.interruptEnable:
            return interruptEnable.rawValue
        default:
            assertionFailure("Failed to read address: \(address)")
            return 0xff
        }
    }

    public func write(byte: Byte, to address: Address) {
        write(byte: byte, to: address, privileged: false)
    }

    /// Passing true for `privileged` allows writing to the MMU even during a DMA transfer
    public func write(byte: Byte, to address: Address, privileged: Bool) {
        if let mask = mask, mask.isAddressMasked(address) {
            mask.write(byte: byte, to: address)
            return
        }

        if isDMATransferActive && !privileged && (0x00..<MemoryMap.OAM.lowerBound).contains(address) {
            // ROM and RAM is inaccessible by the CPU during DMA transfer
            return
        }

        switch address {
        case MemoryMap.ROM:
            cartridge?.write(byte: byte, to: address)
        case MemoryMap.VRAM:
            vram.write(byte: byte, to: address)
        case MemoryMap.externalRAM:
            cartridge?.write(byte: byte, to: address)
        case MemoryMap.WRAM:
            wram.write(byte: byte, to: address)
        case MemoryMap.ECHO: // (Same as C000-DDFF)
            wram.write(byte: byte, to: address - 0x2000)
        case MemoryMap.OAM:
            oam.write(byte: byte, to: address)
        case MemoryMap.unusable:
            // This region of memory is unusable
            break
        case MemoryMap.IO:
            io.write(byte: byte, to: address)
        case MemoryMap.HRAM:
            hram.write(byte: byte, to: address)
        case MemoryMap.interruptEnable:
            interruptEnable = Interrupts(rawValue: byte)
        default:
            assertionFailure("Failed to write address: \(address)")
        }
    }
}

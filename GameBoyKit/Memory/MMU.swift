public final class MMU: MemoryAddressable {
    private(set) var cartridge: CartridgeType?
    let vram: VRAM
    let wram: WRAM
    let oam: OAM
    let io: IO
    let hram: HRAM
    private(set) var interruptEnable: Interrupts = []

    init(vram: VRAM, wram: WRAM, oam: OAM, io: IO, hram: HRAM) {
        self.vram = vram
        self.wram = wram
        self.oam = oam
        self.io = io
        self.hram = hram
    }

    public func load(cartridge: CartridgeType) {
        self.cartridge = cartridge
    }

    public func read(address: Address) -> Byte {
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
            assertionFailure("attempting to access unusable memory")
            return 0
        case MemoryMap.IO:
            return io.read(address: address)
        case MemoryMap.HRAM:
            return hram.read(address: address)
        case MemoryMap.interruptEnable:
            return interruptEnable.rawValue
        default:
            assertionFailure("Failed to read address: \(address)")
            return 0
        }
    }

    public func write(byte: Byte, to address: Address) {
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
            assertionFailure("attempting to access unusable memory")
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

public final class MMU: MemoryAddressable {
	let rom: ROM
	let vram: VRAM
	let wram: WRAM
	let oam: OAM
	let io: IO
	let hram: HRAM
	private var interruptEnable: Interrupts = []

	init(rom: ROM, vram: VRAM, wram: WRAM, oam: OAM, io: IO, hram: HRAM) {
		self.rom = rom
		self.vram = vram
		self.wram = wram
		self.oam = oam
		self.io = io
		self.hram = hram
	}

	public func read(address: Address) -> Byte {
		switch address {
		case MemoryMap.ROM:
			return rom.read(address: address)
		case MemoryMap.VRAM:
			return vram.read(address: address)
		case MemoryMap.ExternalRAM:
			return 0 // todo
		case MemoryMap.WRAM:
			return wram.read(address: address)
		case MemoryMap.ECHO: // (Same as C000-DDFF)
			return wram.read(address: address - 0x2000)
		case MemoryMap.OAM:
			return oam.read(address: address)
		case MemoryMap.Unusable:
			assertionFailure("attempting to access unusable memory")
			return 0
		case MemoryMap.IO:
			return io.read(address: address)
		case MemoryMap.HRAM:
			return hram.read(address: address)
		case MemoryMap.InterruptEnable:
			return interruptEnable.rawValue
		default:
			return 0
		}
	}

	public func write(byte: Byte, to address: Address) {
		switch address {
		case MemoryMap.ROM:
			rom.write(byte: byte, to: address)
		case MemoryMap.VRAM:
			vram.write(byte: byte, to: address)
		case MemoryMap.ExternalRAM:
			break // todo
		case MemoryMap.WRAM:
			wram.write(byte: byte, to: address)
		case MemoryMap.ECHO: // (Same as C000-DDFF)
			wram.write(byte: byte, to: address - 0x2000)
		case MemoryMap.OAM:
			oam.write(byte: byte, to: address)
		case MemoryMap.Unusable:
			assertionFailure("attempting to access unusable memory")
			break
		case MemoryMap.IO:
			io.write(byte: byte, to: address)
		case MemoryMap.HRAM:
			hram.write(byte: byte, to: address)
		case MemoryMap.InterruptEnable:
			interruptEnable = Interrupts(rawValue: byte)
		default:
			break
		}
	}
}

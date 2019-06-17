public struct IORegisters {
	public static let interruptFlags: Address = 0xff0f
	public static let lcdControl: Address = 0xff40
	public static let lcdStatus: Address = 0xff41
	public static let scrollY: Address = 0xff42
	public static let scrollX: Address = 0xff43
	public static let lcdYCoordinate: Address = 0xff44
	public static let lcdYCoordinateCompare: Address = 0xff45
	public static let dmaTransfer: Address = 0xff46
	public static let windowY: Address = 0xff4a
	public static let windowX: Address = 0xff4b
	public static let vramBank: Address = 0xff4f
}

public final class IO: MemoryAddressable {
	public let palette: ColorPalette
	public weak var mmu: MMU?

	public var interruptFlags: Interrupts = []
	public var lcdControl = LCDControl(rawValue: 0)
	public var lcdStatus = LCDStatus(rawValue: 0)
	public var lcdYCoordinate: UInt8 = 0

	private var bytes = [Byte](repeating: 0, count: MemoryMap.IO.count)
	private let oam: OAM

	public init(palette: ColorPalette, oam: OAM) {
		self.palette = palette
		self.oam = oam
	}

	public func read(address: Address) -> Byte {
		switch address {
		case IORegisters.interruptFlags:
			return interruptFlags.rawValue
		case IORegisters.lcdControl:
			return lcdControl.rawValue
		case IORegisters.lcdStatus:
			return lcdStatus.rawValue
		case IORegisters.lcdYCoordinate:
			return lcdYCoordinate
		case palette.monochromeAddressRange, palette.colorAddressRange:
			return palette.read(address: address)
		default:
			return bytes.read(address: address, in: .IO)
		}
	}

	public func write(byte: Byte, to address: Address) {
		switch address {
		case IORegisters.interruptFlags:
			interruptFlags = Interrupts(rawValue: byte)
		case IORegisters.lcdControl:
			lcdControl = LCDControl(rawValue: byte)
		case IORegisters.lcdStatus:
			lcdStatus = LCDStatus(rawValue: byte)
		case IORegisters.lcdYCoordinate:
			lcdYCoordinate = byte
		case palette.monochromeAddressRange, palette.colorAddressRange:
			palette.write(byte: byte, to: address)
		case IORegisters.dmaTransfer:
			if let mmu = mmu {
				oam.dmaTransfer(byte: byte, mmu: mmu)
			} else {
				fatalError("DMA transfer could not be initiated because MMU is nil")
			}
		default:
			bytes.write(byte: byte, to: address, in: .IO)
		}
	}
}

extension IO {
	var scrollY: UInt8 {
		return read(address: IORegisters.scrollY)
	}

	var scrollX: UInt8 {
		return read(address: IORegisters.scrollX)
	}

	var lcdYCoordinateCompare: UInt8 {
		return read(address: IORegisters.lcdYCoordinateCompare)
	}

	var windowY: UInt8 {
		return read(address: IORegisters.windowY)
	}

	var windowX: UInt8 {
		return read(address: IORegisters.windowX)
	}

	var vramBank: UInt8 {
		return read(address: IORegisters.vramBank) & 0x01
	}
}

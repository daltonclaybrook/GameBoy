public final class IO: MemoryAddressable {
	public struct Registers {
		public static let timerRange: ClosedRange<Address> = 0xff04...0xff07
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

	public let palette: ColorPalette
	public weak var mmu: MMU?

	public var interruptFlags: Interrupts = []
	public var lcdControl = LCDControl(rawValue: 0)
	public var lcdStatus = LCDStatus(rawValue: 0)
	public var lcdYCoordinate: UInt8 = 0

	private var bytes = [Byte](repeating: 0, count: MemoryMap.IO.count)
	private let oam: OAM
	private let timer: Timer

	public init(palette: ColorPalette, oam: OAM, timer: Timer) {
		self.palette = palette
		self.oam = oam
		self.timer = timer
		timer.delegate = self
	}

	public func read(address: Address) -> Byte {
		switch address {
		case Registers.timerRange:
			return timer.read(address: address)
		case Registers.interruptFlags:
			return interruptFlags.rawValue
		case Registers.lcdControl:
			return lcdControl.rawValue
		case Registers.lcdStatus:
			return lcdStatus.rawValue
		case Registers.lcdYCoordinate:
			return lcdYCoordinate
		case palette.monochromeAddressRange, palette.colorAddressRange:
			return palette.read(address: address)
		default:
			return bytes.read(address: address, in: .IO)
		}
	}

	public func write(byte: Byte, to address: Address) {
		switch address {
		case Registers.timerRange:
			return timer.write(byte: byte, to: address)
		case Registers.interruptFlags:
			interruptFlags = Interrupts(rawValue: byte)
		case Registers.lcdControl:
			lcdControl = LCDControl(rawValue: byte)
		case Registers.lcdStatus:
			lcdStatus = LCDStatus(rawValue: byte)
		case Registers.lcdYCoordinate:
			lcdYCoordinate = byte
		case palette.monochromeAddressRange, palette.colorAddressRange:
			palette.write(byte: byte, to: address)
		case Registers.dmaTransfer:
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
		return read(address: Registers.scrollY)
	}

	var scrollX: UInt8 {
		return read(address: Registers.scrollX)
	}

	var lcdYCoordinateCompare: UInt8 {
		return read(address: Registers.lcdYCoordinateCompare)
	}

	var windowY: UInt8 {
		return read(address: Registers.windowY)
	}

	var windowX: UInt8 {
		return read(address: Registers.windowX)
	}

	var vramBank: UInt8 {
		return read(address: Registers.vramBank) & 0x01
	}
}

extension IO: TimerDelegate {
	public func timer(_ timer: Timer, didRequest interrupt: Interrupts) {
		interruptFlags.formUnion(interrupt)
	}
}
// Only first 2 bits are used
public typealias ColorNumber = Byte

public struct Color {
	let red: Byte
	let green: Byte
	let blue: Byte
}

public final class ColorPalette {
	public struct Registers {
		public static let monochromeBGData: Address = 0xff47
		public static let monochromeObject0Data: Address = 0xff48
		public static let monochromeObject1Data: Address = 0xff49
		public static let colorBGIndex: Address = 0xff68
		public static let colorBGData: Address = 0xff69
		public static let colorObjectIndex: Address = 0xff6a
		public static let colorObjectData: Address = 0xff6b
	}

	public let monochromeAddressRange: ClosedRange<Address> = (0xff47...0xff49)
	public let colorAddressRange: ClosedRange<Address> = (0xff68...0xff6b)

	private var monochromeBGData: Byte = 0
	private var monochromeObject0Data: Byte = 0
	private var monochromeObject1Data: Byte = 0

	private var colorBGIndex: Byte = 0
	// 8 palettes * 4 colors * 2 bytes per color
	private var colorBGData = [Byte](repeating: 0, count: 8 * 8)

	private var colorObjectIndex: Byte = 0
	// 8 palettes * 4 colors * 2 bytes per color
	private var colorObjectData = [Byte](repeating: 0, count: 8 * 8)

	public init() {}

	public func read(address: Address) -> Byte {
		switch address {
		case Registers.monochromeBGData:
			return monochromeBGData
		case Registers.monochromeObject0Data:
			return monochromeObject0Data
		case Registers.monochromeObject1Data:
			return monochromeObject1Data

		case Registers.colorBGIndex:
			return colorBGIndex
		case Registers.colorBGData:
			let index = colorBGIndex & 0x3f // first six bits form the index
			return colorBGData[Int(index)]
		case Registers.colorObjectIndex:
			return colorObjectIndex
		case Registers.colorObjectData:
			let index = colorObjectIndex & 0x3f // first six bits form the index
			return colorObjectData[Int(index)]
		default:
			fatalError("Attempting to read from invalid address")
		}
	}

	public func write(byte: Byte, to address: Address) {
		switch address {
		case Registers.monochromeBGData:
			monochromeBGData = byte
		case Registers.monochromeObject0Data:
			monochromeObject0Data = byte
		case Registers.monochromeObject1Data:
			monochromeObject1Data = byte

		case Registers.colorBGIndex:
			colorBGIndex = byte
		case Registers.colorBGData:
			let index = colorBGIndex & 0x3f // first six bits form the index
			colorBGData[Int(index)] = byte
			if colorBGIndex & 0x80 != 0 {
				// auto-increment on write
				colorBGIndex += 1
			}
		case Registers.colorObjectIndex:
			colorObjectIndex = byte
		case Registers.colorObjectData:
			let index = colorObjectIndex & 0x3f // first six bits form the index
			colorObjectData[Int(index)] = byte
			if colorObjectIndex & 0x80 != 0 {
				// auto-increment on write
				colorObjectIndex += 1
			}
		default:
			fatalError("Attempting to read from invalid address")
		}
	}

	public func monochromeBGColor(for number: ColorNumber) -> Color {
		let shift = number & 0x03 * 2
		let colorShadeIndex = (monochromeBGData >> shift) & 0x03
		// Possible values are:
		// 0 => 255 (white)
		// 1 => 170 (light gray)
		// 2 => 85 (dark gray)
		// 3 => 0 (black)
		let grayValue = 255 - colorShadeIndex * 85
		return Color(red: grayValue, green: grayValue, blue: grayValue)
	}
}

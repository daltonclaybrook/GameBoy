/// The index 0-3 of the color for a tile. This index refers to a
/// color in a color palette. Only first 2 bits are used.
public typealias ColorNumber = Byte

/// A single color of a pixel in a tile. Values range between 0-255.
public struct Color {
    let red: Byte
    let green: Byte
    let blue: Byte
}

public final class ColorPalettes {
    public enum Palette {
        case monochromeBackgroundAndWindow
        case monochromeObject0
        case monochromeObject1
    }

    public struct Registers {
        public static let monochromeBGAndWindowData: Address = 0xff47
        public static let monochromeObject0Data: Address = 0xff48
        public static let monochromeObject1Data: Address = 0xff49
        public static let backgroundColorPaletteIndex: Address = 0xff68
        public static let backgroundColorPaletteData: Address = 0xff69
        public static let objectColorPaletteIndex: Address = 0xff6a
        public static let objectColorPaletteData: Address = 0xff6b
    }

    public let monochromeAddressRange: ClosedRange<Address> = 0xff47...0xff49
    public var colorPaletteMemoryIsAccessible = true

    /// Clients use this view to access colors from palette memory
    /// at a discrete point in time. Unlike the `ColorPalettes` object,
    /// the `PaletteView` type is thread safe.
    public var currentView: PaletteView {
        PaletteView(
            monochromeBGAndWindowData: monochromeBGAndWindowData,
            monochromeObject0Data: monochromeObject0Data,
            monochromeObject1Data: monochromeObject1Data
        )
    }

    private var monochromeBGAndWindowData: Byte = 0
    private var monochromeObject0Data: Byte = 0
    private var monochromeObject1Data: Byte = 0

    private var backgroundColorPaletteIndex = PaletteIndexAndIncrement(rawValue: 0x00)
    private var objectColorPaletteIndex = PaletteIndexAndIncrement(rawValue: 0x00)
    private var colorBGAndWindowData = [CGBPalette](repeating: .init(), count: 8)
    private var colorObjectData = [CGBPalette](repeating: .init(), count: 8)

    public init() {}

    public func read(address: Address) -> Byte {
        switch address {
        case Registers.monochromeBGAndWindowData:
            return monochromeBGAndWindowData
        case Registers.monochromeObject0Data:
            return monochromeObject0Data
        case Registers.monochromeObject1Data:
            return monochromeObject1Data
        case Registers.backgroundColorPaletteIndex:
            return backgroundColorPaletteIndex.rawValue
        case Registers.backgroundColorPaletteData where colorPaletteMemoryIsAccessible:
            return readColorPaletteData(colorBGAndWindowData, index: backgroundColorPaletteIndex)
        case Registers.objectColorPaletteIndex:
            return objectColorPaletteIndex.rawValue
        case Registers.objectColorPaletteData where colorPaletteMemoryIsAccessible:
            return readColorPaletteData(colorObjectData, index: objectColorPaletteIndex)
        case Registers.backgroundColorPaletteData, Registers.objectColorPaletteData:
            // color palette memory is not current accessible
            return 0xff
        default:
            fatalError("Attempting to read from invalid address")
        }
    }

    public func write(byte: Byte, to address: Address) {
        switch address {
        case Registers.monochromeBGAndWindowData:
            monochromeBGAndWindowData = byte
        case Registers.monochromeObject0Data:
            monochromeObject0Data = byte
        case Registers.monochromeObject1Data:
            monochromeObject1Data = byte
        case Registers.backgroundColorPaletteIndex:
            backgroundColorPaletteIndex.rawValue = byte
        case Registers.backgroundColorPaletteData where colorPaletteMemoryIsAccessible:
            return writeColorPaletteData(&colorBGAndWindowData, byte: byte, indexAndIncrement: &backgroundColorPaletteIndex)
        case Registers.objectColorPaletteIndex:
            objectColorPaletteIndex.rawValue = byte
        case Registers.objectColorPaletteData where colorPaletteMemoryIsAccessible:
            return writeColorPaletteData(&colorObjectData, byte: byte, indexAndIncrement: &objectColorPaletteIndex)
        case Registers.backgroundColorPaletteData, Registers.objectColorPaletteData:
            // color palette memory is not current accessible
            break
        default:
            fatalError("Attempting to read from invalid address")
        }
    }

    // MARK: - Helpers

    private func readColorPaletteData(_ data: [CGBPalette], index: PaletteIndexAndIncrement) -> Byte {
        let index = index.index
        let paletteIndex = Int(index) / 8
        let offsetInPalette = Int(index) % 8
        return data[paletteIndex].getByte(atByteOffset: offsetInPalette)
    }

    private func writeColorPaletteData(_ data: inout [CGBPalette], byte: Byte, indexAndIncrement: inout PaletteIndexAndIncrement) {
        let index = indexAndIncrement.index
        let paletteIndex = Int(index) / 8
        let offsetInPalette = Int(index) % 8
        data[paletteIndex].setByte(byte, atByteOffset: offsetInPalette)
        if indexAndIncrement.autoIncrementOnWrite {
            indexAndIncrement.incrementIndex()
        }
    }
}

/// A view into the current state of palette data. This type is thread safe.
public struct PaletteView {
    let monochromeBGAndWindowData: Byte
    let monochromeObject0Data: Byte
    let monochromeObject1Data: Byte

    public func getColor(for number: ColorNumber, in palette: ColorPalettes.Palette) -> Color {
        let paletteData = getData(for: palette)
        return getMonochromeColor(for: number, data: paletteData)
    }

    // MARK: - Helpers

    private func getData(for palette: ColorPalettes.Palette) -> Byte {
        switch palette {
        case .monochromeBackgroundAndWindow:
            return monochromeBGAndWindowData
        case .monochromeObject0:
            return monochromeObject0Data
        case .monochromeObject1:
            return monochromeObject1Data
        }
    }

    private func getMonochromeColor(for colorNumber: ColorNumber, data: Byte) -> Color {
        let shift = (colorNumber & 0x03) * 2
        let colorShadeIndex = (data >> shift) & 0x03
        // Possible values are:
        // 0 => 255 (white)
        // 1 => 170 (light gray)
        // 2 => 85 (dark gray)
        // 3 => 0 (black)
        let grayValue = 255 - colorShadeIndex * 85
        return Color(red: grayValue, green: grayValue, blue: grayValue)
    }
}

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
    public struct Registers {
        public static let monochromeBGAndWindowData: Address = 0xff47
        public static let monochromeObject0Data: Address = 0xff48
        public static let monochromeObject1Data: Address = 0xff49
        public static let backgroundColorPaletteIndex: Address = 0xff68
        public static let backgroundColorPaletteData: Address = 0xff69
        public static let objectColorPaletteIndex: Address = 0xff6a
        public static let objectColorPaletteData: Address = 0xff6b

        // Palette address ranges
        public static let monochromeAddressRange: ClosedRange<Address> = 0xff47...0xff49
        public static let colorAddressRange: ClosedRange<Address> = 0xff68...0xff6b
    }

    public var colorPaletteMemoryIsAccessible = true

    /// Clients use this view to access colors from palette memory
    /// at a discrete point in time. Unlike the `ColorPalettes` object,
    /// the `PaletteView` type is thread safe.
    public var currentView: PaletteView {
        PaletteView(
            system: system,
            monochromeBGAndWindowPalette: monochromeBGAndWindowPalette,
            monochromeObjectPalettes: [
                monochromeObject0Palette,
                monochromeObject1Palette
            ],
            colorBGAndWindowPalettes: colorBGAndWindowPalettes,
            colorObjectPalettes: colorObjectPalettes
        )
    }

    private let system: GameBoy.System
    private var monochromeBGAndWindowPalette = MonochromePalette()
    private var monochromeObject0Palette = MonochromePalette()
    private var monochromeObject1Palette = MonochromePalette()

    private var backgroundColorPaletteIndex = PaletteIndexAndIncrement(rawValue: 0x00)
    private var objectColorPaletteIndex = PaletteIndexAndIncrement(rawValue: 0x00)
    private var colorBGAndWindowPalettes = [ColorPalette](repeating: .init(), count: 8)
    private var colorObjectPalettes = [ColorPalette](repeating: .init(), count: 8)

    public init(system: GameBoy.System) {
        self.system = system
    }

    public func read(address: Address) -> Byte {
        switch address {
        case Registers.monochromeBGAndWindowData:
            return monochromeBGAndWindowPalette.rawValue
        case Registers.monochromeObject0Data:
            return monochromeObject0Palette.rawValue
        case Registers.monochromeObject1Data:
            return monochromeObject1Palette.rawValue
        case Registers.backgroundColorPaletteIndex:
            return backgroundColorPaletteIndex.rawValue
        case Registers.backgroundColorPaletteData where colorPaletteMemoryIsAccessible:
            return readColorPaletteData(colorBGAndWindowPalettes, index: backgroundColorPaletteIndex)
        case Registers.objectColorPaletteIndex:
            return objectColorPaletteIndex.rawValue
        case Registers.objectColorPaletteData where colorPaletteMemoryIsAccessible:
            return readColorPaletteData(colorObjectPalettes, index: objectColorPaletteIndex)
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
            monochromeBGAndWindowPalette.rawValue = byte
        case Registers.monochromeObject0Data:
            monochromeObject0Palette.rawValue = byte
        case Registers.monochromeObject1Data:
            monochromeObject1Palette.rawValue = byte
        case Registers.backgroundColorPaletteIndex:
            backgroundColorPaletteIndex.rawValue = byte
        case Registers.backgroundColorPaletteData where colorPaletteMemoryIsAccessible:
            return writeColorPaletteData(&colorBGAndWindowPalettes, byte: byte, indexAndIncrement: &backgroundColorPaletteIndex)
        case Registers.objectColorPaletteIndex:
            objectColorPaletteIndex.rawValue = byte
        case Registers.objectColorPaletteData where colorPaletteMemoryIsAccessible:
            return writeColorPaletteData(&colorObjectPalettes, byte: byte, indexAndIncrement: &objectColorPaletteIndex)
        case Registers.backgroundColorPaletteData, Registers.objectColorPaletteData:
            // color palette memory is not current accessible
            break
        default:
            fatalError("Attempting to read from invalid address")
        }
    }

    // MARK: - Helpers

    private func readColorPaletteData(_ palettes: [ColorPalette], index: PaletteIndexAndIncrement) -> Byte {
        let index = index.index
        let paletteIndex = Int(index) / 8
        let offsetInPalette = Int(index) % 8
        return palettes[paletteIndex].getByte(atOffset: offsetInPalette)
    }

    private func writeColorPaletteData(_ palettes: inout [ColorPalette], byte: Byte, indexAndIncrement: inout PaletteIndexAndIncrement) {
        let index = indexAndIncrement.index
        let paletteIndex = Int(index) / 8
        let offsetInPalette = Int(index) % 8
        palettes[paletteIndex].setByte(byte, atOffset: offsetInPalette)
        if indexAndIncrement.autoIncrementOnWrite {
            indexAndIncrement.incrementIndex()
        }
    }
}

/// A view into the current state of palette data. This type is thread safe.
public struct PaletteView {
    public enum TileKind {
        case backgroundAndWindow
        case sprite
    }

    let system: GameBoy.System
    let monochromeBGAndWindowPalette: PaletteType
    let monochromeObjectPalettes: [PaletteType]
    let colorBGAndWindowPalettes: [PaletteType]
    let colorObjectPalettes: [PaletteType]

    public func getColor(number: ColorNumber, attributes: BGMapTileAttributes) -> Color {
        getColor(number: number, kind: .backgroundAndWindow, paletteIndex: Int(attributes.backgroundPaletteNumber))
    }

    public func getColor(number: ColorNumber, attributes: SpriteAttributes) -> Color {
        let paletteNumber: UInt8
        switch system {
        case .dmg:
            paletteNumber = attributes.flags.monochromePaletteNumber
        case .cgb:
            paletteNumber = attributes.flags.cgbPaletteNumber
        }
        return getColor(number: number, kind: .sprite, paletteIndex: Int(paletteNumber))
    }

    // MARK: - Helpers

    private func getColor(number: ColorNumber, kind: TileKind, paletteIndex: Int) -> Color {
        precondition(number < 4)
        precondition(paletteIndex >= 0)

        switch (system, kind) {
        case (.dmg, .backgroundAndWindow):
            return monochromeBGAndWindowPalette.getColor(for: number)
        case (.dmg, .sprite):
            assert(paletteIndex < 2)
            return monochromeObjectPalettes[paletteIndex].getColor(for: number)
        case (.cgb, .backgroundAndWindow):
            assert(paletteIndex < 8)
            return colorBGAndWindowPalettes[paletteIndex].getColor(for: number)
        case (.cgb, .sprite):
            assert(paletteIndex < 8)
            return colorObjectPalettes[paletteIndex].getColor(for: number)
        }
    }
}

public final class IO: MemoryAddressable {
    public struct Registers {
        public static let joypad: Address = 0xff00
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

    public let palettes: ColorPalettes

    public var joypad = Joypad()
    public var interruptFlags: Interrupts = []
    public var lcdControl = LCDControl(rawValue: 0)
    public var lcdStatus = LCDStatus(rawValue: 0)
    public var lcdYCoordinate: UInt8 = 0

    private let oam: OAM
    private let apu: APU
    private let timer: Timer
    private let wram: WRAM

    public init(palettes: ColorPalettes, oam: OAM, apu: APU, timer: Timer, wram: WRAM) {
        self.palettes = palettes
        self.oam = oam
        self.apu = apu
        self.timer = timer
        self.wram = wram
        timer.delegate = self
        joypad.delegate = self
    }

    public func read(address: Address) -> Byte {
        switch address {
        case Registers.joypad:
            return joypad.rawValue
        case Registers.timerRange:
            return timer.read(address: address)
        case Registers.interruptFlags:
            return interruptFlags.rawValue
        case APU.Registers.lowerRange, APU.Registers.upperRange:
            return apu.read(address: address)
        case Registers.lcdControl:
            return lcdControl.rawValue
        case Registers.lcdStatus:
            return lcdStatus.rawValue
        case Registers.lcdYCoordinate:
            return lcdYCoordinate
//        case palette.monochromeAddressRange, palette.colorAddressRange:
        case palettes.monochromeAddressRange:
            return palettes.read(address: address)
        case WRAM.Constants.bankSelectAddress:
            return wram.read(address: address)
        default:
            print("Attempting to read from unsupported I/O address: \(address.hexString)")
            return 0xff
        }
    }

    public func write(byte: Byte, to address: Address) {
        switch address {
        case Registers.joypad:
            joypad.update(byte: byte)
        case Registers.timerRange:
            timer.write(byte: byte, to: address)
        case Registers.interruptFlags:
            interruptFlags = Interrupts(rawValue: byte)
        case APU.Registers.lowerRange, APU.Registers.upperRange:
            apu.write(byte: byte, to: address)
        case Registers.lcdControl:
            lcdControl = LCDControl(rawValue: byte)
        case Registers.lcdStatus:
            lcdStatus = LCDStatus(rawValue: byte)
        case Registers.lcdYCoordinate:
            lcdYCoordinate = byte
//        case palette.monochromeAddressRange, palette.colorAddressRange:
        case palettes.monochromeAddressRange:
            palettes.write(byte: byte, to: address)
        case Registers.dmaTransfer:
            oam.startDMATransfer(source: byte)
        case WRAM.Constants.bankSelectAddress:
            wram.write(byte: byte, to: address)
        default:
            print("Attempting to write to unsupported I/O address: \(address.hexString)")
            break
        }
    }
}

extension IO {
    var scrollY: UInt8 {
        read(address: Registers.scrollY)
    }

    var scrollX: UInt8 {
        read(address: Registers.scrollX)
    }

    var lcdYCoordinateCompare: UInt8 {
        read(address: Registers.lcdYCoordinateCompare)
    }

    var windowY: UInt8 {
        read(address: Registers.windowY)
    }

    var windowX: UInt8 {
        read(address: Registers.windowX)
    }

    var vramBank: UInt8 {
        read(address: Registers.vramBank) & 0x01
    }
}

extension IO: TimerDelegate {
    public func timer(_ timer: Timer, didRequest interrupt: Interrupts) {
        interruptFlags.formUnion(interrupt)
    }
}

extension IO: JoypadDelegate {
    public func joypadDidRequestInterrupt(_ joypad: Joypad) {
        interruptFlags.insert(.joypad)
    }
}

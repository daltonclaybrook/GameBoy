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
        public static let speedSwitch: Address = 0xff4d
        public static let disableBootRom: Address = 0xff50
        public static let vramDMARange: ClosedRange<Address> = 0xff51...0xff55
    }

    public let palettes: ColorPalettes

    public var joypad = Joypad()
    public var interruptFlags: Interrupts = []
    public var lcdControl = LCDControl(rawValue: 0)
    public var lcdStatus = LCDStatus(rawValue: 0)

    public private(set) var scrollY: UInt8 = 0
    public private(set) var scrollX: UInt8 = 0
    public var lcdYCoordinate: UInt8 = 0
    public private(set) var lcdYCoordinateCompare: UInt8 = 0
    public private(set) var windowY: UInt8 = 0
    public private(set) var windowX: UInt8 = 0

    private let oam: OAM
    private let apu: APU
    private let timer: Timer
    private let vram: VRAM
    private let wram: WRAM
    private let speed: SystemSpeed
    private let bootROM: BootROM?

    public init(palettes: ColorPalettes, oam: OAM, apu: APU, timer: Timer, vram: VRAM, wram: WRAM, speed: SystemSpeed, bootROM: BootROM?) {
        self.palettes = palettes
        self.oam = oam
        self.apu = apu
        self.timer = timer
        self.vram = vram
        self.wram = wram
        self.speed = speed
        self.bootROM = bootROM
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
        case Registers.scrollY:
            return scrollY
        case Registers.scrollX:
            return scrollX
        case Registers.lcdYCoordinate:
            return lcdYCoordinate
        case Registers.lcdYCoordinateCompare:
            return lcdYCoordinateCompare
        case ColorPalettes.Registers.monochromeAddressRange,
             ColorPalettes.Registers.colorAddressRange:
            return palettes.read(address: address)
        case Registers.windowY:
            return windowY
        case Registers.windowX:
            return windowX
        case Registers.speedSwitch:
            return speed.read(address: address)
        case Registers.disableBootRom:
            return bootROM?.read(address: address) ?? 0xff
        case VRAM.Constants.bankSelectAddress:
            return vram.read(address: address)
        case WRAM.Constants.bankSelectAddress:
            return wram.read(address: address)
        case Registers.vramDMARange:
            return vram.dmaUtility?.read(address: address) ?? 0xff
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
        case Registers.scrollY:
            scrollY = byte
        case Registers.scrollX:
            scrollX = byte
        case Registers.lcdYCoordinate:
            lcdYCoordinate = byte
        case Registers.lcdYCoordinateCompare:
            lcdYCoordinateCompare = byte
        case ColorPalettes.Registers.monochromeAddressRange,
             ColorPalettes.Registers.colorAddressRange:
            palettes.write(byte: byte, to: address)
        case Registers.dmaTransfer:
            oam.startDMATransfer(source: byte)
        case Registers.windowY:
            windowY = byte
        case Registers.windowX:
            windowX = byte
        case Registers.speedSwitch:
            speed.write(byte: byte, to: address)
        case Registers.disableBootRom:
            bootROM?.write(byte: byte, to: address)
        case VRAM.Constants.bankSelectAddress:
            vram.write(byte: byte, to: address)
        case WRAM.Constants.bankSelectAddress:
            wram.write(byte: byte, to: address)
        case Registers.vramDMARange:
            vram.dmaUtility?.write(byte: byte, to: address)
        default:
            print("Attempting to write to unsupported I/O address: \(address.hexString)")
            break
        }
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

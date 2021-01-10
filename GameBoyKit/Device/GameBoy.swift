import Foundation

public struct InterruptVectors {
    public static let vBlank: Address = 0x0040
    public static let lcdStat: Address = 0x0048
    public static let timer: Address = 0x0050
    public static let serial: Address = 0x0058
    public static let joypad: Address = 0x0060
}

public final class GameBoy {
    private let queue = DispatchQueue(
        label: "com.daltonclaybrook.GameBoy.GameBoy",
        qos: .userInteractive
    )
    private let clock: Clock
    private let timer: Timer
    private let cpu: CPU
    private let ppu: PPU
    private let io: IO
    private let mmu: MMU

    private let vram = VRAM()
    private let palette = ColorPalette()
    private var cartridge: CartridgeType?

    /// Advance by this amount each step if the CPU is halted
    private let haltedCycleStep: Cycles = 2

    public init(renderer: Renderer) {
        clock = Clock(queue: queue)
        timer = Timer()
        let oam = OAM()
        io = IO(palette: palette, oam: oam, timer: timer)
        ppu = PPU(renderer: renderer, io: io, vram: vram)
        mmu = MMU(vram: vram, wram: WRAM(), oam: oam, io: io, hram: HRAM())
        io.mmu = mmu
        cpu = CPU(mmu: mmu)
    }

    public func load(cartridge: CartridgeType) {
        self.cartridge = cartridge
        mmu.load(cartridge: cartridge)
        bootstrap()
        clock.start(stepBlock: stepAndReturnCycles)
    }

    private func stepAndReturnCycles() -> Cycles {
        //		if cpu.pc == 0xC2B9 { // interrupt test #2
        //		if cpu.pc == 49856 {
        //			print("test 1")
        //		}
        //		if cpu.pc == 49845 {
        //			print("test 2")
        //		}
        //		if cpu.pc == 0xC2E4 { // interrupt test #3
        //			print("test 3")
        //		}
        //		if cpu.pc == 50789 {
        //			print("test 4")
        //		}
        //		if cpu.pc == 2004 {
        //			print("break")
        //		}
        timer.step(clock: clock.cycles)
        ppu.step(clock: clock.cycles)
        let cycles: Cycles
        if !cpu.isHalted {
            let opcodeByte = mmu.read(address: cpu.pc)
            let opcode = CPU.allOpcodes[Int(opcodeByte)]
            //			print("\(opcode.mnemonic) PC: \(cpu.pc)")
            cycles = opcode.block(cpu)
        } else {
            cycles = haltedCycleStep
        }

        processInterruptIfNecessary()

        let threshold = 3_000_000
        if clock.cycles < threshold && clock.cycles + cycles >= threshold {
            vram.writeDebugImagesAndDataToDisk(io: io)
        }
        return cycles
    }

    private func bootstrap() {
        cpu.a = 0x01
        cpu.flags = Flags(rawValue: 0xb0)
        cpu.c = 0x13
        cpu.e = 0xd8
        cpu.sp = 0xfffe
        cpu.pc = 0x100

        mmu.write(byte: 0x80, to: 0xff10)
        mmu.write(byte: 0xbf, to: 0xff11)
        mmu.write(byte: 0xf3, to: 0xff12)
        mmu.write(byte: 0xbf, to: 0xff14)
        mmu.write(byte: 0x3f, to: 0xff16)
        mmu.write(byte: 0xbf, to: 0xff19)
        mmu.write(byte: 0x7f, to: 0xff1a)
        mmu.write(byte: 0xff, to: 0xff1b)
        mmu.write(byte: 0x9f, to: 0xff1c)
        mmu.write(byte: 0xbf, to: 0xff1e)
        mmu.write(byte: 0xff, to: 0xff20)
        mmu.write(byte: 0xbf, to: 0xff23)
        mmu.write(byte: 0x77, to: 0xff24)
        mmu.write(byte: 0xf3, to: 0xff25)
        mmu.write(byte: 0xf1, to: 0xff26)
        mmu.write(byte: 0x91, to: 0xff40)
        mmu.write(byte: 0xfc, to: 0xff47)
        mmu.write(byte: 0xff, to: 0xff48)
        mmu.write(byte: 0xff, to: 0xff49)
    }

    private func processInterruptIfNecessary() {
        if cpu.isHalted &&
            !cpu.interuptsEnabled &&
            !mmu.interruptEnable.intersection(io.interruptFlags).isEmpty {
            // disable halt without processing interrupts
            cpu.isHalted = false
            return
        }

        guard cpu.interuptsEnabled else { return }
        defer { io.interruptFlags = [] }

        if mmu.interruptEnable.contains(.vBlank) && io.interruptFlags.contains(.vBlank) {
            callInterrupt(vector: InterruptVectors.vBlank)
        } else if mmu.interruptEnable.contains(.lcdStat) && io.interruptFlags.contains(.lcdStat) {
            callInterrupt(vector: InterruptVectors.lcdStat)
        } else if mmu.interruptEnable.contains(.timer) && io.interruptFlags.contains(.timer) {
            callInterrupt(vector: InterruptVectors.timer)
        } else if mmu.interruptEnable.contains(.serial) && io.interruptFlags.contains(.serial) {
            callInterrupt(vector: InterruptVectors.serial)
        } else if mmu.interruptEnable.contains(.joypad) && io.interruptFlags.contains(.joypad) {
            callInterrupt(vector: InterruptVectors.joypad)
        }
    }

    private func callInterrupt(vector: Address) {
        cpu.interuptsEnabled = false
        cpu.isHalted = false
        mmu.write(word: cpu.pc, to: cpu.sp - 2)
        cpu.sp &-= 2
        cpu.pc = vector
    }
}

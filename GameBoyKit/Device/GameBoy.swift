import Foundation

public struct InterruptVectors {
    public static let vBlank: Address = 0x0040
    public static let lcdStat: Address = 0x0048
    public static let timer: Address = 0x0050
    public static let serial: Address = 0x0058
    public static let joypad: Address = 0x0060
}

public final class GameBoy {
    /// The type of system to emulate
    public enum System: Int {
        /// The original monochrome Game Boy
        case dmg
        /// The Game Boy Color
        case cgb
    }

    private let delegateQueue: DispatchQueue
    private let queue = DispatchQueue(
        label: "com.daltonclaybrook.GameBoy.GameBoy",
        qos: .userInteractive
    )

    public var joypad: Joypad {
        io.joypad
    }

    public let ppu: PPU
    public let vram: VRAM
    public let io: IO

    let cpu: CPU
    let mmu: MMU
    let system: System

    private let clock: Clock
    private let timer: Timer
    private let oam: OAM
    private let wram: WRAM
    private let palettes: ColorPalettes
    private let speed: SystemSpeed
    private let bootROM: BootROM?
    private let hram = HRAM()
    private let apu = APU()
    private var cartridge: CartridgeType?
    private let emulationSteppers: [EmulationStepType]

    public init(system: System, renderer: Renderer, delegateQueue: DispatchQueue = .main) {
        self.system = system
        timer = Timer()
        oam = OAM(system: system)
        wram = WRAM(system: system)
        vram = VRAM(system: system)
        palettes = ColorPalettes(system: system)
        speed = SystemSpeed(system: system)
        clock = Clock(systemSpeed: speed, queue: queue)
        bootROM = try! BootROM(system: self.system)
        io = IO(
            palettes: palettes,
            oam: oam,
            apu: apu,
            timer: timer,
            vram: vram,
            wram: wram,
            speed: speed,
            bootROM: bootROM
        )
        ppu = PPU(renderer: renderer, system: system, io: io, vram: vram, oam: oam)
        mmu = MMU(vram: vram, wram: wram, oam: oam, io: io, hram: hram)
        oam.mmu = mmu
        cpu = CPU()
        emulationSteppers = [oam, ppu, apu, timer]
        self.delegateQueue = delegateQueue
        bootROM?.delegate = self
    }

    public func load(cartridgeInfo: CartridgeInfo) {
        queue.async {
            self.cartridge = cartridgeInfo.cartridge
            self.mmu.load(cartridge: cartridgeInfo.cartridge)
            self.mmu.mask = self.bootROM
//            self.bootstrap()
        }
    }

    public func start() {
        queue.async {
            guard self.cartridge != nil else { return }
            self.clock.start { [weak self] in
                self?.fetchAndExecuteNextInstruction()
            }
            self.apu.start()
        }
    }

    public func shutdown() {
        // This might be called as the owner of GameBoy is being torn down,
        // so we use `queue.sync` to make sure the clock is stopped before
        // that happens.
        queue.sync {
            self.clock.stop()
            self.apu.stop()
        }
    }

    // MARK: - Helpers

    private func fetchAndExecuteNextInstruction() {
        let previousQueuedEnableInterrupts = cpu.queuedEnableInterrupts

        if !cpu.isHalted {
            let opcodeByte = cpu.fetchByte(context: self)
            let opcode = CPU.allOpcodes[Int(opcodeByte)]
            opcode.executeBlock(cpu, self)
        } else {
            tickCycle()
        }

        // If enable interrupts was queued in the previous instruction and not dequeued in
        // this instruction, interrupts will be enabled.
        if previousQueuedEnableInterrupts && cpu.queuedEnableInterrupts {
            cpu.queuedEnableInterrupts = false
            cpu.interruptsEnabled = true
        }

        // todo: evaluate when it's appropriate to do this. This should probably
        // occur on a step of its own, not after a step has occurred.
        processInterruptIfNecessary()
    }

    private func disableBootROM() {
        // Boot ROM execution has finished. By setting the MMU mask to nil,
        // we are effectively unloading the boot ROM and making 0x00...0xff
        // accessible on the cartridge ROM.
        mmu.mask = nil
        switch system {
        case .dmg:
            cpu.a = 0x01
        case .cgb:
            cpu.a = 0x11
        }
    }

    /// This function is called each time the system should advance by 1 M-cycle.
    /// These cases include MMU reads/writes and when the CPU performs an internal
    /// function necessitating a cycle, such as a jump.
    private func emulateCycle() {
        clock.tickCycle()
        let speedMode = speed.currentMode

        for stepper in emulationSteppers {
            switch (speedMode, stepper.stepRate) {
            case (.normal, _):
                // Call step on every cycle
                stepper.emulateStep()
            case (.double, .matchSpeedMode):
                // Call step on every cycle, including in double speed
                stepper.emulateStep()
            case (.double, .alwaysNormalSpeed) where clock.cycles % 2 == 0:
                // Call step half as frequently while in double speed mode
                stepper.emulateStep()
            default:
                break
            }
        }
    }

    private func processInterruptIfNecessary() {
        if cpu.isHalted && !cpu.interruptsEnabled {
            // disable halt without processing interrupts
            cpu.isHalted = false
            return
        }

        guard cpu.interruptsEnabled else { return }

        if mmu.interruptEnable.contains(.vBlank) && io.interruptFlags.contains(.vBlank) {
            callInterrupt(vector: InterruptVectors.vBlank, flag: .vBlank)
        } else if mmu.interruptEnable.contains(.lcdStat) && io.interruptFlags.contains(.lcdStat) {
            callInterrupt(vector: InterruptVectors.lcdStat, flag: .lcdStat)
        } else if mmu.interruptEnable.contains(.timer) && io.interruptFlags.contains(.timer) {
            callInterrupt(vector: InterruptVectors.timer, flag: .timer)
        } else if mmu.interruptEnable.contains(.serial) && io.interruptFlags.contains(.serial) {
            callInterrupt(vector: InterruptVectors.serial, flag: .serial)
        } else if mmu.interruptEnable.contains(.joypad) && io.interruptFlags.contains(.joypad) {
            callInterrupt(vector: InterruptVectors.joypad, flag: .joypad)
        }
    }

    private func callInterrupt(vector: Address, flag: Interrupts) {
        io.interruptFlags.remove(flag)
        cpu.interruptsEnabled = false
        cpu.isHalted = false
        tickCycle()
        tickCycle()
        cpu.pushStack(value: cpu.pc, context: self)
        cpu.pc = vector
    }
}

extension GameBoy: CPUContext {
    public func readCycle(address: Address) -> Byte {
        emulateCycle()
        return mmu.read(address: address)
    }

    public func writeCycle(byte: Byte, to address: Address) {
        emulateCycle()
        mmu.write(byte: byte, to: address)
    }

    public func tickCycle() {
        emulateCycle()
    }

    public func stopAndSwitchSpeedsIfNecessary() {
        clock.switchSpeedsIfNecessary()
    }
}

extension GameBoy: BootRomDelegate {
    public func bootROMShouldBeDisabled(_ bootRom: BootROM) {
        disableBootROM()
    }
}

import Foundation

public struct InterruptVectors {
    public static let vBlank: Address = 0x0040
    public static let lcdStat: Address = 0x0048
    public static let timer: Address = 0x0050
    public static let serial: Address = 0x0058
    public static let joypad: Address = 0x0060
}

public protocol GameBoyDelegate: AnyObject {
    func gameBoy(_ gameBoy: GameBoy, didSaveExternalRAM bytes: [Byte])
}

public final class GameBoy {
    private let delegateQueue: DispatchQueue
    private let queue = DispatchQueue(
        label: "com.daltonclaybrook.GameBoy.GameBoy",
        qos: .userInteractive
    )

    public weak var delegate: GameBoyDelegate?

    public var joypad: Joypad {
        io.joypad
    }

    public let ppu: PPU
    let cpu: CPU
    let mmu: MMU
    private let clock: Clock
    private let timer: Timer
    private let oam: OAM
    private let io: IO

    private let vram = VRAM()
    private let wram = WRAM()
    private let hram = HRAM()
    private let palettes = ColorPalettes()
    private var cartridge: CartridgeType?

    public init(renderer: Renderer, displayLink: DisplayLinkType, delegateQueue: DispatchQueue = .main) {
        clock = Clock(queue: queue, displayLink: displayLink)
        timer = Timer()
        oam = OAM()
        io = IO(palettes: palettes, oam: oam, timer: timer)
        ppu = PPU(renderer: renderer, io: io, vram: vram, oam: oam)
        mmu = MMU(vram: vram, wram: wram, oam: oam, io: io, hram: hram)
        oam.mmu = mmu
        cpu = CPU()
        self.delegateQueue = delegateQueue
    }

    public func load(cartridge: CartridgeType) {
        queue.async {
            self.cartridge = cartridge
            self.cartridge?.delegate = self
            self.mmu.load(cartridge: cartridge)
            self.mmu.mask = try! BootROM.dmgBootRom()
//            self.bootstrap()
        }
    }

    public func start() {
        queue.async {
            guard self.cartridge != nil else { return }
            self.clock.start { [weak self] in
                self?.fetchAndExecuteNextInstruction()
            }
        }
    }

    public func stop() {
        // This might be called as the owner of GameBoy is being torn down,
        // so we use `queue.sync` to make sure the clock is stopped before
        // that happens.
        queue.sync {
            self.clock.stop()
        }
    }

    // MARK: - Helpers

    private func fetchAndExecuteNextInstruction() {
        if mmu.mask != nil && cpu.pc == 0x100 {
            // Boot ROM execution has finished. By setting the MMU mask to nil,
            // we are effectively unloading the boot ROM and making 0x00...0xff
            // accessible on the cartridge ROM.
            mmu.mask = nil
            bootstrap()
        }

        let previousQueuedEnableInterrupts = cpu.queuedEnableInterrupts

        if !cpu.isHalted {
//            let pc = cpu.pc
            let opcodeByte = cpu.fetchByte(context: self)
            let opcode = CPU.allOpcodes[Int(opcodeByte)]
//            print("PC: \(pc.hexString), \(opcode.mnemonic)")
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

    /// This function is called each time the system should advance by 1 M-cycle.
    /// These cases include MMU reads/writes and when the CPU performs an internal
    /// function necessitating a cycle, such as a jump.
    private func emulateCycle() {
        clock.tickCycle()
        // emulate components
        oam.emulate()
        ppu.emulate()
        // emulate timer
        timer.emulate()
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
}

extension GameBoy: CartridgeDelegate {
    public func cartridge(_ cartridge: CartridgeType, didSaveExternalRAM bytes: [Byte]) {
        delegateQueue.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.gameBoy(self, didSaveExternalRAM: bytes)
        }
    }
}

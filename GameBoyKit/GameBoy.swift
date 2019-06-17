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
	private let cpu: CPU
	private let ppu: PPU
	private let io: IO
	private let mmu: MMU

	private let rom = ROM()
	private let vram = VRAM()
	private let palette = ColorPalette()

	public init(renderer: Renderer) {
		clock = Clock(queue: queue)
		let oam = OAM()
		io = IO(palette: palette, oam: oam)
		ppu = PPU(renderer: renderer, io: io, vram: vram)
		mmu = MMU(rom: rom, vram: vram, wram: WRAM(), oam: oam, io: io, hram: HRAM())
		io.mmu = mmu
		cpu = CPU(mmu: mmu)
	}

	public func loadROM(data: Data) {
		rom.loadROM(data: data)
		bootstrap()
		clock.start(stepBlock: stepAndReturnCycles)
	}

	private func stepAndReturnCycles() -> Cycles {
		ppu.step(clock: clock.cycles)
		let opcodeByte = mmu.read(address: cpu.pc)
		let opcode = CPU.allOpcodes[Int(opcodeByte)]
//		print("\(opcode.mnemonic) PC: \(cpu.pc)")
		let cycles = opcode.block(cpu)
		processInterruptIfNecessary()
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
		defer { io.interruptFlags = [] }
		guard cpu.interuptsEnabled else { return }

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
		mmu.write(word: cpu.pc &+ 1, to: cpu.sp - 2)
		cpu.sp &-= 2
		cpu.pc = vector
	}
}

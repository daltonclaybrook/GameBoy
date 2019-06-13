public final class GameBoy {
	private let queue: DispatchQueue = DispatchQueue(
		label: "com.daltonclaybrook.GameBoy.GameBoy",
		qos: .userInteractive
	)
	private let clock: Clock
	private let cpu: CPU
	private let ppu: PPU
	private let io: IO

	private let mmu = MMU()
	private let rom = ROM()
	private let palette = ColorPalette()

	public init(renderer: Renderer) {
		clock = Clock(queue: queue)
		cpu = CPU(mmu: mmu)
		let oam = OAM(mmu: mmu)
		let vram = VRAM()
		io = IO(palette: palette, oam: oam)
		ppu = PPU(renderer: renderer, io: io, vram: vram)

		mmu.register(device: rom)
		mmu.register(device: vram)
		// todo: cartridge RAM
		mmu.register(device: WRAM())
		// todo: ECHO
		mmu.register(device: oam)
		mmu.register(device: io)
		mmu.register(device: HRAM())
	}

	public func loadROM(data: Data) {
		rom.loadROM(data: data)
		bootstrap()
		clock.start(stepBlock: stepAndReturnCycles)
	}

	private func stepAndReturnCycles() -> Cycles {
		let opcodeByte = mmu.read(address: cpu.pc)
		let opcode = CPU.allOpcodes[Int(opcodeByte)]
		let cycles = opcode.block(cpu)
		ppu.step(cycles: cycles)
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
}

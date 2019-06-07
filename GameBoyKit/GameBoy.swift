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
	private let palette = ColorPalette()

	public init() {
		clock = Clock(queue: queue)
		cpu = CPU(mmu: mmu)
		let oam = OAM(mmu: mmu)
		let vram = VRAM()
		io = IO(palette: palette, oam: oam)
		ppu = PPU(io: io, vram: vram)

		mmu.register(device: ROM())
		mmu.register(device: vram)
		mmu.register(device: io)
		mmu.register(device: oam)
	}

	public func start() {
		clock.start(stepBlock: stepAndReturnCycles)
	}

	private func stepAndReturnCycles() -> Cycles {
		let a = 20 + 30
		let b = a | 7
		let c = a
		let d = b + c
		_ = d
		return 1
	}
}

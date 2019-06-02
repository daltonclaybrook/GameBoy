public final class GameBoy {
	private let queue: DispatchQueue = DispatchQueue(
		label: "com.daltonclaybrook.GameBoy.GameBoy",
		qos: .userInteractive
	)
	private let clock: Clock
	private let cpu: CPU
	private let mmu = MMU()
	private let ppu = PPU()

	public init() {
		clock = Clock(queue: queue)
		cpu = CPU(mmu: mmu)
		mmu.register(device: ROM())
		mmu.register(device: VRAM(ppu: ppu))
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

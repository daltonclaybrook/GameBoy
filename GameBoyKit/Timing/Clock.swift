/// Machine cycles, or m-cycles
public typealias Cycles = UInt64
public typealias CyclesPerSecond = UInt64

public final class Clock {
	private(set) public var isRunning = false
	private(set) public var cycles: Cycles = 0

	let timeSpeed: UInt64 = 4_194_304 // 4.194 MHz
	/// Machine Speed is Time Speed divided by 4
	///
	/// Each CPU instruction takes a certain number of T (time) states to
	/// execute, and it just so happens that all instructions @ 4 MHz have
	/// a duration in T that is divisible by 4, so, for example, it's more intuitive to
	/// talk about 2 M (machine) cycles @ 1 MHz vs 8 T states @ 4 MHz.
	let machineSpeed: CyclesPerSecond

	private let queue: DispatchQueue
	private let cyclesPerBatch: Cycles = 10_000
	private let secondsPerMCycle: TimeInterval

	/// - Parameters:
	///   - queue: The dispatch queue where the clock will be advanced and the
	///   block will be executed
	///   - advanceBlock: The block which will be executed on each new clock
	///   cycle. Returns the number of cycles to advance the clock.
	init(queue: DispatchQueue) {
		self.queue = queue
		machineSpeed = timeSpeed / 4
		secondsPerMCycle = 1.0 / TimeInterval(machineSpeed)
	}

	func start(stepBlock: @escaping () -> Cycles) {
		queue.async {
			self.isRunning = true
			self.advanceClock(stepBlock: stepBlock)
		}
	}

	func stop() {
		queue.async {
			self.isRunning = false
		}
	}

//	private var delays: [TimeInterval] = []
	private func advanceClock(stepBlock: @escaping () -> Cycles) {
		let startDate = Date()
		var cycles: Cycles = 0
		while cycles < cyclesPerBatch {
			let stepCycles = stepBlock()
			cycles += stepCycles
			self.cycles += stepCycles
		}
		let timeElapsed = -startDate.timeIntervalSinceNow
		let delay = TimeInterval(cycles) * secondsPerMCycle - timeElapsed
//		print("advancing with delay: \(delay)")
//		delays.append(delay)
//		if delays.count == 600 {
//			print("delay average: \(delays.reduce(0, +) / TimeInterval(delays.count))")
//		}
		scheduleAdvanceClockIfRunning(afterDelay: delay, stepBlock: stepBlock)
	}

	private func scheduleAdvanceClockIfRunning(afterDelay: TimeInterval, stepBlock: @escaping () -> Cycles) {
		guard isRunning else { return }
		queue.asyncAfter(deadline: .now() + max(afterDelay, 0)) { [weak self] in
			self?.advanceClock(stepBlock: stepBlock)
		}
	}
}

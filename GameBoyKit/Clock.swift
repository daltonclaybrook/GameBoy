public typealias Cycles = UInt64
public typealias CyclesPerSecond = UInt64

public final class Clock {
	private(set) public var isRunning = false

	private let queue: DispatchQueue
	private let cyclesPerBatch: Cycles = 10_000
	private let baseSpeed: UInt64 = 4_194_304 // 4.194 MHz
	/// Clock Speed is Base Speed divided by 4
	///
	/// Each CPU instruction takes a certain number of machine cycles to
	/// execute, and it just so happens that all instructions @ 4 MHz have a
	/// cycle count that is divisible by 4, so it's more productive to talk
	/// about 2 cycles @ 1 MHz vs 8 cycles @ 4 MHz.
	private let clockSpeed: CyclesPerSecond
	private let secondsPerCycle: TimeInterval

	/// - Parameters:
	///   - queue: The dispatch queue where the clock will be advanced and the
	///   block will be executed
	///   - advanceBlock: The block which will be executed on each new clock
	///   cycle. Returns the number of cycles to advance the clock.
	init(queue: DispatchQueue) {
		self.queue = queue
		clockSpeed = baseSpeed / 4
		secondsPerCycle = 1.0 / TimeInterval(clockSpeed)
	}

	func start(stepBlock: @escaping () -> Cycles) {
		queue.sync {
			isRunning = true
			advanceClock(stepBlock: stepBlock)
		}
	}

	func stop() {
		queue.sync {
			isRunning = false
		}
	}

	private func advanceClock(stepBlock: @escaping () -> Cycles) {
		let startDate = Date()
		var cycles: Cycles = 0
		while cycles < cyclesPerBatch {
			cycles += stepBlock()
		}
		let timeElapsed = -startDate.timeIntervalSinceNow
		let delay = TimeInterval(cycles) * secondsPerCycle - timeElapsed
//		print("advancing with delay: \(delay)")
		scheduleAdvanceClockIfRunning(afterDelay: delay, stepBlock: stepBlock)
	}

	private func scheduleAdvanceClockIfRunning(afterDelay: TimeInterval, stepBlock: @escaping () -> Cycles) {
		guard isRunning else { return }
		queue.asyncAfter(deadline: .now() + max(afterDelay, 0)) { [weak self] in
			self?.advanceClock(stepBlock: stepBlock)
		}
	}
}

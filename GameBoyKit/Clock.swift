public typealias Cycles = Int
public typealias CyclesPerSecond = Int

public final class Clock {
	private(set) public var isRunning = false

	private let queue: DispatchQueue
	private let baseSpeed = 4_194_304 // 4.194 MHz
	/// Clock Speed is Base Speed divided by 4
	///
	/// Each CPU instruction takes a certain number of machine cycles to
	/// execute, and it just so happens that all instructions @ 4 MHz have a
	/// cycle count that is divisible by 4, so it's more productive to talk
	/// about 2 cycles @ 1 MHz vs 8 cycles @ 4 MHz.
	private let clockSpeed: CyclesPerSecond
	private let secondsPerCycle: TimeInterval
	private let advanceBlock: () -> Cycles

	/// - Parameters:
	///   - queue: The dispatch queue where the clock will be advanced and the
	///   block will be executed
	///   - advanceBlock: The block which will be executed on each new clock
	///   cycle. Returns the number of cycles to advance the clock.
	init(queue: DispatchQueue, advanceBlock: @escaping () -> Cycles) {
		self.queue = queue
		self.advanceBlock = advanceBlock
		clockSpeed = baseSpeed / 4
		secondsPerCycle = 1.0 / TimeInterval(clockSpeed)
	}

	func start() {
		isRunning = true
		queue.sync {
			isRunning = true
			advanceClock()
		}
	}

	private func advanceClock() {
		let startDate = Date()
		let cycles = advanceBlock()
		let timeElapsed = -startDate.timeIntervalSinceNow
		let delay = TimeInterval(cycles) * secondsPerCycle - timeElapsed
		scheduleAdvanceClockIfRunning(afterDelay: delay)
	}

	private func scheduleAdvanceClockIfRunning(afterDelay: TimeInterval) {
		guard isRunning else { return }
		queue.asyncAfter(deadline: .now() + afterDelay, execute: advanceClock)
	}
}

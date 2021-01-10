import Foundation

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
    private let cyclesPerFrame: Cycles
    private let framesPerSecond: UInt64 = 60
    private let frameDuration: TimeInterval

    /// - Parameters:
    ///   - queue: The dispatch queue where the clock will be advanced and the
    ///   block will be executed
    init(queue: DispatchQueue) {
        self.queue = queue
        frameDuration = 1.0 / TimeInterval(framesPerSecond)
        machineSpeed = timeSpeed / 4
        cyclesPerFrame = machineSpeed / framesPerSecond
    }

    func start(stepBlock: @escaping () -> Cycles) {
        queue.async {
            self.isRunning = true
            self.emulateFrame(stepBlock: stepBlock)
        }
    }

    func stop() {
        queue.async {
            self.isRunning = false
        }
    }

    private func emulateFrame(stepBlock: @escaping () -> Cycles) {
        let startDate = Date()

        var cycles: Cycles = 0
        while cycles < cyclesPerFrame {
            let stepCycles = stepBlock()
            cycles += stepCycles
            self.cycles += stepCycles
        }
        let timeElapsed = -startDate.timeIntervalSinceNow
        let delay = max(frameDuration - timeElapsed, 0)
        scheduleAdvanceClockIfRunning(afterDelay: delay, stepBlock: stepBlock)
    }

    private func scheduleAdvanceClockIfRunning(afterDelay: TimeInterval, stepBlock: @escaping () -> Cycles) {
        precondition(afterDelay >= 0)
        guard isRunning else { return }
        queue.asyncAfter(deadline: .now() + afterDelay) { [weak self] in
            self?.emulateFrame(stepBlock: stepBlock)
        }
    }
}

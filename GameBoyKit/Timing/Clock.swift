import Foundation

/// Machine cycles, or m-cycles
public typealias Cycles = UInt64
public typealias CyclesPerSecond = UInt64

public final class Clock {
    private(set) public var isRunning = false
    private(set) public var cycles: Cycles = 0

    /// The real speed of the processor. This value is rarely used in practice.
    public static let processorSpeed: CyclesPerSecond = 4_194_304 // 4.194 MHz

    /// This value is the `processorSpeed` divided by four.
    ///
    /// Each instruction takes a certain number of clocks of the CPU, and this number
    /// is always divisible by four. Because of this, the available documentation tends
    /// to describe durations in "machine cycles" rather than the actual number of CPU
    /// cycles, and many emulators prefer to use this number because it is easier to
    /// work with.
    public static let effectiveMachineSpeed: CyclesPerSecond = processorSpeed / 4

    /// The speed of the timer used to drive emulation. Rather that set a timer to run
    /// at ~1 MHz (which is impractical), we use a fairly arbitrary value of 256 Hz.
    private let timerSpeed: CyclesPerSecond = 256

    private let queue: DispatchQueue
    private var emulateBlock: (() -> Void)?
    private var lastCycleOverflow: Cycles = 0
    private var timer: DispatchSourceTimer?

    /// - Parameters:
    ///   - queue: The dispatch queue where the clock will be advanced and the
    ///   block will be executed
    init(queue: DispatchQueue) {
        self.queue = queue
    }

    /// Begin emulation by starting the display link. The provided `emulateBlock`
    /// will be called periodically on the dispatch queue provided in the initializer.
    /// The Game Boy should read/evaluate a CPU instruction each time this block is
    /// called, and should advance the other components of the system accordingly.
    func start(emulateBlock: @escaping () -> Void) {
        self.emulateBlock = emulateBlock
        isRunning = true

        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        self.timer = timer
        timer.setEventHandler {
            self.timerDidFire(speed: self.timerSpeed)
        }
        let timeInterval = 1.0 / TimeInterval(timerSpeed)
        timer.schedule(deadline: .now(), repeating: timeInterval)
        timer.resume()
    }

    func stop() {
        isRunning = false
        emulateBlock = nil
        timer?.setEventHandler(handler: nil)
        timer?.cancel()
        timer = nil
    }

    func tickCycle() {
        cycles += 1
    }

    // MARK: - Helpers

    private func timerDidFire(speed: CyclesPerSecond) {
        guard let emulateBlock = emulateBlock else { return }
        let currentFrameCycles = Self.effectiveMachineSpeed / speed
        let targetCycles = currentFrameCycles - lastCycleOverflow

        let startCycles = cycles
        while cycles - startCycles < targetCycles {
            emulateBlock()
        }
        lastCycleOverflow = cycles - startCycles - targetCycles
    }
}

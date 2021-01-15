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
    private let displayLink: DisplayLinkType
    private var stepBlock: (() -> Cycles)?
    private var lastCycleOverflow: Cycles = 0

    /// - Parameters:
    ///   - queue: The dispatch queue where the clock will be advanced and the
    ///   block will be executed
    init(queue: DispatchQueue, displayLink: DisplayLinkType) {
        self.queue = queue
        self.displayLink = displayLink
        self.machineSpeed = timeSpeed / 4
        displayLink.setRenderCallback { [weak self] framesPerSecond in
            self?.displayLinkDidFire(framesPerSecond: framesPerSecond)
        }
    }

    func start(stepBlock: @escaping () -> Cycles) {
        queue.async {
            self.isRunning = true
            self.stepBlock = stepBlock
            self.displayLink.start()
        }
    }

    func stop() {
        queue.async {
            self.isRunning = false
            self.stepBlock = nil
            self.displayLink.stop()
        }
    }

    func tickCycle() {
        cycles += 1
    }

    // MARK: - Helpers

    private func displayLinkDidFire(framesPerSecond: FramesPerSecond) {
        queue.async {
            let currentFrameCycles = Cycles(Double(self.machineSpeed) / framesPerSecond)
            let targetCycles = currentFrameCycles - self.lastCycleOverflow

            var cycles: Cycles = 0
            while cycles < targetCycles {
                let stepCycles = self.stepBlock?() ?? 0
                cycles += stepCycles
                self.cycles += stepCycles
            }
            self.lastCycleOverflow = cycles - targetCycles
        }
    }
}

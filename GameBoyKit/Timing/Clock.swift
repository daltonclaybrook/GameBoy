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
    private var emulateBlock: (() -> Void)?
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

    /// Begin emulation by starting the display link. The provided `emulateBlock`
    /// will be called periodically on the dispatch queue provided in the initializer.
    /// The Game Boy should read/evaluate a CPU instruction each time this block is
    /// called, and should advance the other components of the system accordingly.
    func start(emulateBlock: @escaping () -> Void) {
        self.emulateBlock = emulateBlock
        isRunning = true
        displayLink.start()
    }

    func stop() {
        isRunning = false
        emulateBlock = nil
        displayLink.stop()
    }

    func tickCycle() {
        cycles += 1
    }

    // MARK: - Helpers

    private func displayLinkDidFire(framesPerSecond: FramesPerSecond) {
        queue.async {
            let currentFrameCycles = Cycles(Double(self.machineSpeed) / framesPerSecond)
            let targetCycles = currentFrameCycles - self.lastCycleOverflow

            let startCycles = self.cycles
            while self.cycles - startCycles < targetCycles {
                self.emulateBlock?()
            }
            self.lastCycleOverflow = self.cycles - startCycles - targetCycles
        }
    }
}

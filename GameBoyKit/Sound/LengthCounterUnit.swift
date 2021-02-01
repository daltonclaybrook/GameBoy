public final class LengthCounterUnit {
    public var isEnabled: Bool {
        remainingCycles > 0
    }

    private var remainingCycles: UInt8 = 0
    private let maxCycles: UInt8 = 64

    func load(soundLength: UInt8) {
        remainingCycles = maxCycles - min(soundLength, maxCycles)
    }

    func clockTick() {
        guard remainingCycles > 0 else { return }
        remainingCycles -= 1
    }
}

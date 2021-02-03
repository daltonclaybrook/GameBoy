public final class SweepUnit {
    public private(set) var isEnabled = false

    private let channel: SweepChannel & FrequencyChannel
    private var shadowFrequencyRegister: UInt16 = 0
    private var cyclesRemaining: UInt8 = 0

    public init(channel: SweepChannel & FrequencyChannel) {
        self.channel = channel
    }

    func restart() {
        isEnabled = channel.sweepCycleModulus > 0 && channel.sweepShiftNumber > 0
        shadowFrequencyRegister = channel.combinedFrequencyRegister
        cyclesRemaining = channel.sweepCycleModulus
    }

    func reset() {
        isEnabled = false
    }

    func clockTick() {
        guard updateAndReturnIsEnabled() else { return }

        cyclesRemaining -= 1
        guard cyclesRemaining == 0 else { return }
        cyclesRemaining = channel.sweepCycleModulus

        let currentFrequency = Int32(shadowFrequencyRegister)
        let nextFrequency = (currentFrequency >> channel.sweepShiftNumber) * channel.sweepDirection.multiplier + currentFrequency
        guard nextFrequency <= 2047 else {
            isEnabled = false
            return
        }

        shadowFrequencyRegister = UInt16(nextFrequency)
        channel.update(frequency: shadowFrequencyRegister)
    }

    // MARK: - Helpers

    private func updateAndReturnIsEnabled() -> Bool {
        guard isEnabled else { return false }
        isEnabled = channel.sweepCycleModulus > 0 && channel.sweepShiftNumber > 0
        return isEnabled
    }
}

private extension SweepVolumeDirection {
    /// Used in the sweep calculation
    var multiplier: Int32 {
        switch self {
        case .increasing:
            return 1
        case .decreasing:
            return -1
        }
    }
}

public final class SweepUnit {
    private let channel1: Channel1
    private var isEnabled = false
    private var shadowFrequencyRegister: UInt16 = 0
    private var cyclesRemaining: UInt8 = 0

    public init(channel1: Channel1) {
        self.channel1 = channel1
    }

    func restart() {
        isEnabled = channel1.sweepCycleModulus > 0 && channel1.sweepShiftNumber > 0
        shadowFrequencyRegister = channel1.combinedFrequencyRegister
        cyclesRemaining = channel1.sweepCycleModulus
    }

    func clockTick() {
        guard updateAndReturnIsEnabled() else { return }

        cyclesRemaining -= 1
        guard cyclesRemaining == 0 else { return }
        cyclesRemaining = channel1.sweepCycleModulus

        let currentFrequency = Int32(shadowFrequencyRegister)
        let nextFrequency = (currentFrequency >> channel1.sweepShiftNumber) * channel1.sweepDirection.multiplier + currentFrequency
        guard nextFrequency <= 2047 else {
            isEnabled = false
            return
        }

        shadowFrequencyRegister = UInt16(nextFrequency)
        channel1.combinedFrequencyRegister = shadowFrequencyRegister
    }

    // MARK: - Helpers

    private func updateAndReturnIsEnabled() -> Bool {
        guard isEnabled else { return false }
        isEnabled = channel1.sweepCycleModulus > 0 && channel1.sweepShiftNumber > 0
        return isEnabled
    }
}

private extension Channel1.Direction {
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

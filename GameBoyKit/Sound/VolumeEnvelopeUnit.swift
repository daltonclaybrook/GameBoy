public final class VolumeEnvelopeUnit {
    public private(set) var currentVolume: UInt8 = 0

    private let channel1: Channel1
    private var isEnabled = false
    private var cyclesRemaining: UInt8 = 0
    private let volumeRange: ClosedRange<Int8> = 0...15

    public init(channel1: Channel1) {
        self.channel1 = channel1
    }

    func restart() {
        currentVolume = channel1.initialVolumeOfEnvelope
        cyclesRemaining = channel1.envelopeCycleModulus
        isEnabled = cyclesRemaining > 0
    }

    func clockTick() {
        guard updateAndReturnIsEnabled() else { return }

        cyclesRemaining -= 1
        guard cyclesRemaining == 0 else { return }
        cyclesRemaining = channel1.envelopeCycleModulus

        let unclampedVolume = (Int8(currentVolume) + channel1.envelopeDirection.adjustment)
        currentVolume = UInt8(unclampedVolume.clamped(to: volumeRange))

        if !volumeRange.contains(unclampedVolume) {
            // Stop calculation until next trigger if new volume is outside the allowable range
            isEnabled = false
        }
    }

    // MARK: - Helpers

    private func updateAndReturnIsEnabled() -> Bool {
        guard isEnabled else { return false }
        isEnabled = channel1.envelopeCycleModulus > 0
        return isEnabled
    }
}

private extension Channel1.Direction {
    /// Used in the volume adjustment
    var adjustment: Int8 {
        switch self {
        case .increasing:
            return 1
        case .decreasing:
            return -1
        }
    }
}

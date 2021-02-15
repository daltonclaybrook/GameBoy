public final class VolumeEnvelopeUnit {
    public private(set) var currentVolume: UInt8 = 0
    public var normalizedVolume: Float {
        Float(currentVolume) / Float(volumeRange.upperBound)
    }

    private let channel: VolumeEnvelopeChannel
    private var isEnabled = false
    private var cyclesRemaining: UInt8 = 0
    private let volumeRange: ClosedRange<Int8> = 0...15

    public init(channel: VolumeEnvelopeChannel) {
        self.channel = channel
    }

    func restart() {
        currentVolume = channel.initialVolumeOfEnvelope
        cyclesRemaining = channel.envelopeCycleModulus
        isEnabled = cyclesRemaining > 0
    }

    func reset() {
        cyclesRemaining = 0
        isEnabled = false
    }

    func clockTick() {
        guard updateAndReturnIsEnabled() else { return }

        cyclesRemaining -= 1
        guard cyclesRemaining == 0 else { return }
        cyclesRemaining = channel.envelopeCycleModulus

        let unclampedVolume = (Int8(currentVolume) + channel.envelopeDirection.adjustment)
        currentVolume = UInt8(unclampedVolume.clamped(to: volumeRange))

        if !volumeRange.contains(unclampedVolume) {
            // Stop calculation until next trigger if new volume is outside the allowable range
            isEnabled = false
        }
    }

    // MARK: - Helpers

    private func updateAndReturnIsEnabled() -> Bool {
        guard isEnabled else { return false }
        isEnabled = channel.envelopeCycleModulus > 0
        return isEnabled
    }
}

private extension SweepVolumeDirection {
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

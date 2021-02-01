public final class LengthCounterUnit {
    /// When this value is false, the channel is disabled and should
    /// not play sound. This is affected by the remaining cycles in
    /// the length counter and whether sound length is enabled in the
    /// appropriate channel register.
    public var channelIsEnabled: Bool {
        remainingCycles > 0 || !channel1.isSoundLengthEnabled
    }

    private let channel1: Channel1
    private let control: SoundControl
    private let maxCycles: UInt8 = 64
    private var remainingCycles: UInt8 = 0 {
        didSet {
            if remainingCycles == 0 && channel1.isSoundLengthEnabled {
                control.enabledChannels.remove(.channel1)
            }
        }
    }

    public init(channel1: Channel1, control: SoundControl) {
        self.channel1 = channel1
        self.control = control
    }

    func restart() {
        updateRemainingCycles(soundLength: channel1.soundLength)
    }

    public func load(soundLength: UInt8) {
        updateRemainingCycles(soundLength: soundLength)
    }

    public func clockTick() {
        guard remainingCycles > 0 else { return }
        remainingCycles -= 1
    }

    // MARK: - Helpers

    private func updateRemainingCycles(soundLength: UInt8) {
        let adjustedLength: UInt8 = soundLength == 0 ? 64 : 0
        remainingCycles = maxCycles - min(adjustedLength, maxCycles)
    }
}

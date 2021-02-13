public final class LengthCounterUnit {
    /// This value is used to determine if sound is allowed to pass through this unit
    /// without being suppressed. Sound may pass through if the length counter is
    /// disabled, or if the specified sound length has not completely elapsed since
    /// restart.
    public var isAllowingSound: Bool {
        !isLengthEnabled || remainingCycles > 0
    }

    private let channel: LengthChannel
    private let control: SoundControl
    private let maxCycles: UInt16
    private var remainingCycles: UInt16 = 0
    private var isLengthEnabled = false

    public init(channel: LengthChannel, control: SoundControl) {
        self.channel = channel
        self.control = control
        maxCycles = UInt16(channel.getLengthMask()) + 1
    }

    func restart() {
        control.enabledChannels.insert(channel.controlFlag)
        let length = channel.soundLength == 0
            ? maxCycles
            : UInt16(channel.soundLength)
        isLengthEnabled = channel.isSoundLengthEnabled
        if isLengthEnabled {
            remainingCycles = maxCycles - length
        }
    }

    func reset() {
        // no-op
    }

    public func load(soundLength: UInt8) {
        // no-op
    }

    public func clockTick() {
        guard isLengthEnabled && remainingCycles > 0 else { return }

        remainingCycles -= 1
        if remainingCycles == 0 {
            control.enabledChannels.remove(channel.controlFlag)
        }
    }
}

public final class LengthCounterUnit {
    public private(set) var isEnabled = false

    private let channel: LengthChannel
    private let control: SoundControl
    private let maxCycles: UInt16
    private var remainingCycles: UInt16 = 0
    private var nextLength: UInt16 = 0

    public init(channel: LengthChannel, control: SoundControl) {
        self.channel = channel
        self.control = control
        maxCycles = UInt16(channel.getLengthMask()) + 1
    }

    func restart() {
        isEnabled = true
        remainingCycles = nextLength
    }

    func reset() {
        // no-op
    }

    public func load(soundLength: UInt8) {
        nextLength = maxCycles - UInt16(soundLength)
    }

    public func clockTick() {
        guard remainingCycles > 0 && channel.isSoundLengthEnabled else { return }

        remainingCycles -= 1
        if remainingCycles == 0 {
            isEnabled = false
            control.enabledChannels.remove(channel.controlFlag)
        }
    }
}

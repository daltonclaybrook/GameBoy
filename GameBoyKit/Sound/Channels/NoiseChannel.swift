public final class NoiseChannel: LengthChannel, VolumeEnvelopeChannel {
    public var firstRegisterAddress: Address {
        return 0xff1f
    }

    public var controlFlag: SoundControl.ChannelFlags {
        return .channel4
    }

    public weak var delegate: ChannelDelegate?
    public var soundLength: UInt8 = 0
    public var isSoundLengthEnabled = false
    public var volumeEnvelopeRegister: Byte = 0
    /// The internal shift register used to produce the noise
    private let shiftRegister = LFSR()
    private var noiseRegister: Byte = 0
    private var frequency: Float = 0.0

    public func getLengthMask() -> UInt8 { 0x3f }

    public func reset() {
        soundLength = 0
        isSoundLengthEnabled = false
        volumeEnvelopeRegister = 0
    }

    // MARK: - Writes

    public func writeSweepInfoOrWaveEnabled(byte: Byte) {
        // no-op
    }

    public func writeLowFrequencyOrNoiseInfo(byte: Byte) {
        self.noiseRegister = byte
        let dividingRatio = byte & 0x07 // 3 bits
        let ratio = dividingRatio == 0 ? Float(0.5) : Float(dividingRatio)
        shiftRegister.widthMode = LFSR.WidthMode(rawValue: (byte >> 3) & 1)!
        let shiftFrequency = (byte >> 4) & 0x0f // 4 bits
        frequency = 524_288 / ratio / pow(2.0, Float(shiftFrequency) + 1.0)
    }

    public func writeTriggerLengthEnableAndHighFrequency(byte: Byte) {
        isSoundLengthEnabled = (byte >> 6) & 1 == 1
        if (byte >> 7) & 1 == 1 {
            delegate?.channelShouldRestart(self)
        }
    }

    // MARK: - Reads

    public func getSweepInfoOrWaveEnabled() -> Byte {
        // no-op
        return 0x00
    }

    public func getLowFrequencyOrNoiseInfo() -> Byte {
        return noiseRegister
    }
}

public final class NoiseSampleProvider: SampleProviding {
    private let sampleRate: Float
    private let channel: NoiseChannel
    private let control: SoundControl
    private let lengthCounterUnit: LengthCounterUnit
    private let volumeEnvelopeUnit: VolumeEnvelopeUnit

    private var currentPhase: Float = 0
    private var currentVolume: StereoVolume

    private var amplitude: Float {
        guard control.isSoundEnabled && lengthCounterUnit.isAllowingSound
        else { return 0 }
        return volumeEnvelopeUnit.normalizedVolume * amplitudeMultiplier
    }

    public init(
        sampleRate: Float,
        channel: NoiseChannel,
        control: SoundControl,
        lengthCounterUnit: LengthCounterUnit,
        volumeEnvelopeUnit: VolumeEnvelopeUnit
    ) {
        self.sampleRate = sampleRate
        self.channel = channel
        self.control = control
        self.lengthCounterUnit = lengthCounterUnit
        self.volumeEnvelopeUnit = volumeEnvelopeUnit
        currentVolume = control.getStereoVolume(for: channel.controlFlag)
    }

    public func generateSample() -> StereoSample {
        let shift = channel.frequency * twoPi / sampleRate
        currentPhase += shift
        if currentPhase >= twoPi {
            currentPhase.formTruncatingRemainder(dividingBy: twoPi)
            channel.shift()
        }

        let signal = channel.currentSignal * amplitude
        return StereoSample(
            left: signal * currentVolume.leftVolume,
            right: signal * currentVolume.rightVolume
        )
    }

    public func soundControlDidUpdateRouting() {
        currentVolume = control.getStereoVolume(for: channel.controlFlag)
    }

    public func restart() {
        currentPhase = 0
    }
}

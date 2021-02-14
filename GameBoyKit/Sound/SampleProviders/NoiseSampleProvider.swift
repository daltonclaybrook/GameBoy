public final class NoiseSampleProvider: SampleProviding {
    private let channel: NoiseChannel
    private let control: SoundControl
    private let lengthCounterUnit: LengthCounterUnit
    private let volumeEnvelopeUnit: VolumeEnvelopeUnit

    private var currentVolume: MasterStereoVolume

    private var amplitude: Float {
        guard control.isSoundEnabled && lengthCounterUnit.isAllowingSound
        else { return 0 }
        return volumeEnvelopeUnit.normalizedVolume * 0.1
    }

    public init(
        channel: NoiseChannel,
        control: SoundControl,
        lengthCounterUnit: LengthCounterUnit,
        volumeEnvelopeUnit: VolumeEnvelopeUnit
    ) {
        self.channel = channel
        self.control = control
        self.lengthCounterUnit = lengthCounterUnit
        self.volumeEnvelopeUnit = volumeEnvelopeUnit
        currentVolume = control.getStereoVolume(for: channel.controlFlag)
    }

    public func generateSample() -> StereoSample {
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
        // no-op
    }
}

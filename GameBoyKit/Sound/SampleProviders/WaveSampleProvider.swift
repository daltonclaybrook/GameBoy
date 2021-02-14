public final class WaveSampleProvider: SampleProviding {
    private let sampleRate: Float
    private let channel: WaveChannel
    private let control: SoundControl
    private let wavePattern: WavePattern
    private let lengthCounterUnit: LengthCounterUnit

    private var currentPhase: Float = 0
    private var currentVolume: StereoVolume

    private var amplitude: Float {
        guard control.isSoundEnabled &&
                lengthCounterUnit.isAllowingSound &&
                channel.isWaveEnabled
        else { return 0 }
        return channel.volume.percent * 0.1
    }

    public init(
        sampleRate: Float,
        channel: WaveChannel,
        control: SoundControl,
        wavePattern: WavePattern,
        lengthCounterUnit: LengthCounterUnit
    ) {
        self.sampleRate = sampleRate
        self.channel = channel
        self.control = control
        self.wavePattern = wavePattern
        self.lengthCounterUnit = lengthCounterUnit
        currentVolume = control.getStereoVolume(for: channel.controlFlag)
    }

    public func generateSample() -> StereoSample {
        let shift = channel.waveFrequency * twoPi / sampleRate
        currentPhase += shift
        let magnitude = getSignal(currentPhase: currentPhase)
        let signal = magnitude * amplitude
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

    // MARK: - Helpers

    private func getSignal(currentPhase: Float) -> Float {
        let normalizedPhase = currentPhase / twoPi
        let sample = wavePattern.getSample(atNormalizedPhase: normalizedPhase)

        // value in the range -1.0 - 1.0
        let normalizedSignal = (Float(sample) / 0x0f) * 2 - 1
        return normalizedSignal
    }
}

public final class SquareSampleProvider: SampleProviding {
    private let sampleRate: Float
    private let channel: FrequencyChannel & WaveDutyChannel
    private let control: SoundControl
    private let lengthCounterUnit: LengthCounterUnit
    private let volumeEnvelopeUnit: VolumeEnvelopeUnit

    private var currentPhase: Float = 0
    private var currentVolume: StereoVolume

    private var amplitude: Float {
        guard control.isSoundEnabled && lengthCounterUnit.isAllowingSound
        else { return 0 }
        return volumeEnvelopeUnit.normalizedVolume * 0.1
    }

    init(
        sampleRate: Float,
        channel: FrequencyChannel & WaveDutyChannel,
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
        let frequency = channel.squareFrequency
        let shift = frequency * twoPi / sampleRate
        currentPhase += shift

        let harmonics = calculateBandLimitedHarmonics(forFrequency: channel.squareFrequency)
        let magnitude = getSignal(fromHarmonics: harmonics, currentPhase: currentPhase)
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

    private struct MemoKey: Hashable {
        let frequency: Float
        let dutyCycle: Float
    }

    private static var harmonicsCache = Cache<MemoKey, [Float]>()
    /// Calculate the set of coefficients used to produce band-limited square waves.
    /// Producing signals using this method eliminates audible artifacts. More info
    /// here: https://www.nayuki.io/page/band-limited-square-waves
    private func calculateBandLimitedHarmonics(forFrequency frequency: Float) -> [Float] {
        let dutyCycle = channel.waveDuty.percent
        let key = MemoKey(frequency: frequency, dutyCycle: dutyCycle)
        if let harmonics = Self.harmonicsCache.value(forKey: key) {
            return harmonics
        }

        let harmonicsCount = Int(sampleRate / (frequency * 2))
        var harmonics: [Float] = []
        harmonics.reserveCapacity(harmonicsCount + 1)
        harmonics.append(dutyCycle - 0.5) // Start with the duty cycle coefficient

        (1..<(harmonicsCount + 1)).forEach { index in
            let floatIndex = Float(index)
            let nextHarmonic = sin(floatIndex * dutyCycle * .pi) * 2 / (floatIndex * .pi)
            harmonics.append(nextHarmonic)
        }

        Self.harmonicsCache.insert(harmonics, forKey: key)
        return harmonics
    }

    private func getSignal(fromHarmonics harmonics: [Float], currentPhase: Float) -> Float {
        (1..<harmonics.count).reduce(harmonics[0]) { result, index in
            result + cos(Float(index) * currentPhase) * harmonics[index]
        }
    }
}

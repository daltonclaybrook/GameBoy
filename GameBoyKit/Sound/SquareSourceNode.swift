import AVFoundation

public protocol AudioSourceNode {
    func makeSourceNode() -> AVAudioSourceNode
    func restart()
}

private protocol AudioDataProvider {
    var frequency: Float { get }
    var sampleRate: Float { get }
    var amplitude: Float { get }

    func calculateBandLimitedHarmonics(forFrequency frequency: Float) -> [Float]
    func getSignal(fromHarmonics harmonics: [Float], currentPhase: Float) -> Float
}

public final class SquareSourceNode: AudioSourceNode, AudioDataProvider {
    fileprivate let sampleRate: Float

    private let channel: FrequencyChannel & WaveDutyChannel
    private let control: SoundControl
    private let lengthCounterUnit: LengthCounterUnit
    private let volumeEnvelopeUnit: VolumeEnvelopeUnit

    fileprivate var frequency: Float {
        channel.squareFrequency
    }

    fileprivate var amplitude: Float {
        guard control.isSoundEnabled && lengthCounterUnit.isEnabled
        else { return 0 }
        return volumeEnvelopeUnit.normalizedVolume * 0.1
    }

    public init(
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
    }

    public func makeSourceNode() -> AVAudioSourceNode {
        AVAudioSourceNode(renderBlock: createAudioRenderBlock(provider: self))
    }

    public func restart() {
        // no-op
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
    fileprivate func calculateBandLimitedHarmonics(forFrequency frequency: Float) -> [Float] {
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

    fileprivate func getSignal(fromHarmonics harmonics: [Float], currentPhase: Float) -> Float {
        (1..<harmonics.count).reduce(harmonics[0]) { result, index in
            result + cos(Float(index) * currentPhase) * harmonics[index]
        }
    }
}

// MARK: - Free helper functions

private func createAudioRenderBlock(provider: AudioDataProvider) -> AVAudioSourceNodeRenderBlock {
    let twoPi = 2 * Float.pi
    var currentPhase: Float = 0

    return { isSilence, timestamp, frameCount, audioBufferList in
        // The interval by which we advance the phase each frame.
        let frequency = provider.frequency
        let phaseIncrement = (twoPi / provider.sampleRate) * frequency
        let amplitude = provider.amplitude
        guard amplitude > 0 else {
            isSilence.pointee = true
            return noErr
        }

        let harmonics = provider.calculateBandLimitedHarmonics(forFrequency: frequency)
        let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
        for frame in 0..<Int(frameCount) {
            // Get signal value for this frame at time.
            let signal = provider.getSignal(fromHarmonics: harmonics, currentPhase: currentPhase)
            let value = signal * amplitude
            // Advance the phase for the next frame.
            currentPhase += phaseIncrement
            if currentPhase >= twoPi {
                currentPhase -= twoPi
            }
            // Set the same value on all channels (due to the inputFormat we have only 1 channel though).
            for buffer in buffers {
                let bufferPointer = UnsafeMutableBufferPointer<Float>(buffer)
                bufferPointer[frame] = value
            }
        }

        return noErr
    }
}

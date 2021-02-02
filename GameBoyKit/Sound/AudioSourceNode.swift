import AVFoundation

private protocol AudioDataProvider {
    var frequency: Float { get }
    var sampleRate: Float { get }
    var amplitude: Float { get }

    func calculateCoefficients(forFrequency frequency: Float) -> [Float]
    func getSignal(fromCoefficients coefficients: [Float], currentPhase: Float) -> Float
}

final class AudioSourceNode: AudioDataProvider {
    fileprivate let sampleRate: Float

    private let channel: Channel1
    private let control: SoundControl
    private let lengthCounterUnit: LengthCounterUnit
    private let volumeEnvelopeUnit: VolumeEnvelopeUnit
    private let lock = NSRecursiveLock()

    fileprivate var frequency: Float {
        channel.frequency
    }

    fileprivate var amplitude: Float {
        guard control.isSoundEnabled && lengthCounterUnit.channelIsEnabled
        else { return 0 }
        return volumeEnvelopeUnit.normalizedVolume * 0.1
    }

    init(
        sampleRate: Float,
        channel: Channel1,
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

    func makeSourceNode() -> AVAudioSourceNode {
        AVAudioSourceNode(renderBlock: createAudioRenderBlock(provider: self))
    }

    struct MemoKey: Hashable {
        let frequency: Float
        let dutyCycle: Float
    }

    private static var coefficientsMemo: [MemoKey: [Float]] = [:]
    /// Calculate the set of coefficients used to produce band-limited square waves.
    /// Producing signals using this method eliminates audible artifacts. More info
    /// here: https://www.nayuki.io/page/band-limited-square-waves
    fileprivate func calculateCoefficients(forFrequency frequency: Float) -> [Float] {
        let dutyCycle = channel.waveDuty.percent
        let key = MemoKey(frequency: frequency, dutyCycle: dutyCycle)
        if let coefficients = Self.coefficientsMemo[key] {
            return coefficients
        }

        let harmonicsCount = Int(sampleRate / (frequency * 2))
        var coefficients: [Float] = []
        coefficients.reserveCapacity(harmonicsCount + 1)
        coefficients.append(dutyCycle - 0.5) // Start with the duty cycle coefficient

        (1..<(harmonicsCount + 1)).forEach { index in
            let floatIndex = Float(index)
            let nextCoefficient = sin(floatIndex * dutyCycle * .pi) * 2 / (floatIndex * .pi)
            coefficients.append(nextCoefficient)
        }

        lock.lock()
        Self.coefficientsMemo[key] = coefficients
        lock.unlock()
        return coefficients
    }

    fileprivate func getSignal(fromCoefficients coefficients: [Float], currentPhase: Float) -> Float {
        (1..<coefficients.count).reduce(coefficients[0]) { result, index in
            result + cos(Float(index) * currentPhase) * coefficients[index]
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

        let coefficients = provider.calculateCoefficients(forFrequency: frequency)
        let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
        for frame in 0..<Int(frameCount) {
            // Get signal value for this frame at time.
            let signal = provider.getSignal(fromCoefficients: coefficients, currentPhase: currentPhase)
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

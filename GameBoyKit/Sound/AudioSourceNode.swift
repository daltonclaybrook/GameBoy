import AVFoundation

private protocol AudioDataProvider {
    var frequency: Float { get }
    var sampleRate: Float { get }
    var amplitude: Float { get }

    func getSignal(forCurrentPhase phase: Float) -> Float
}

private let twoPi = 2 * Float.pi

final class AudioSourceNode: AudioDataProvider {
    fileprivate let sampleRate: Float

    private let channel: Channel1
    private let control: SoundControl
    private let lengthCounterUnit: LengthCounterUnit
    private let volumeEnvelopeUnit: VolumeEnvelopeUnit

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

    fileprivate func getSignal(forCurrentPhase phase: Float) -> Float {
        let waveform = channel.waveDuty.waveform
        let index = Int((phase / twoPi) * Float(waveform.count))
        return waveform[index]
    }
}

// MARK: - Free helper functions

private func createAudioRenderBlock(provider: AudioDataProvider) -> AVAudioSourceNodeRenderBlock {
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

        let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
        for frame in 0..<Int(frameCount) {
            // Get signal value for this frame at time.
            let signal = provider.getSignal(forCurrentPhase: currentPhase)
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

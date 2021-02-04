import AVFoundation

private protocol AudioDataProvider {
    var frequency: Float { get }
    var sampleRate: Float { get }
    var amplitude: Float { get }

    func getSignal(currentPhase: inout Float) -> Float
}

private let twoPi = 2 * Float.pi

public final class WaveSourceNode: AudioSourceNode, AudioDataProvider {
    fileprivate let sampleRate: Float

    private let channel: WaveChannel
    private let wavePattern: WavePattern
    private let control: SoundControl
    private let lengthCounterUnit: LengthCounterUnit
    private let lock = NSRecursiveLock()
    private var queuedResetCurrentPhase = false

    fileprivate var frequency: Float {
        channel.waveFrequency
    }

    fileprivate var amplitude: Float {
        guard control.isSoundEnabled &&
                lengthCounterUnit.channelIsEnabled &&
                channel.isWaveEnabled
        else { return 0 }
        return channel.volume.percent * 0.1
    }

    public init(
        sampleRate: Float,
        channel: WaveChannel,
        wavePattern: WavePattern,
        control: SoundControl,
        lengthCounterUnit: LengthCounterUnit
    ) {
        self.sampleRate = sampleRate
        self.channel = channel
        self.wavePattern = wavePattern
        self.control = control
        self.lengthCounterUnit = lengthCounterUnit
    }

    public func makeSourceNode() -> AVAudioSourceNode {
        AVAudioSourceNode(renderBlock: createAudioRenderBlock(provider: self))
    }

    public func restart() {
        setQueuedResetCurrentPhase(true)
    }

    // MARK: - Helpers

    fileprivate func getSignal(currentPhase: inout Float) -> Float {
        if queuedResetCurrentPhase {
            setQueuedResetCurrentPhase(false)
            currentPhase = 0
        }

        // phase range 0..<1
        let normalizedPhase = currentPhase / twoPi
        let sampleIndex = min(Int(normalizedPhase * 32), 31)
        let byteIndex = sampleIndex / 2
        // high nibble is played first
        let shiftInByte = sampleIndex % 2 == 0 ? 4 : 0
        let byte = wavePattern.bytes[byteIndex]
        // value in the range 0 - 15
        let nibble = (byte >> shiftInByte) & 0x0f
        // value in the range -1.0 - 1.0
        let normalizedSignal = (Float(nibble) / 0x0f) * 2 - 1
        return normalizedSignal
    }

    private func setQueuedResetCurrentPhase(_ reset: Bool) {
        lock.lock()
        defer { lock.unlock() }
        queuedResetCurrentPhase = reset
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
            let signal = provider.getSignal(currentPhase: &currentPhase)
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

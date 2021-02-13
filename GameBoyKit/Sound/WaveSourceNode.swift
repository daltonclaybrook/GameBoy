import AVFoundation

private typealias QueuedSignal = (left: Float, right: Float)

private protocol AudioDataProvider: AnyObject {
    func getQueuedSignal() -> QueuedSignal?
}

private let twoPi = 2 * Float.pi

public final class WaveSourceNode: AudioSourceNode, AudioDataProvider {
    fileprivate let sampleRate: Float
    fileprivate private(set) var currentVolume: MasterStereoVolume

    private let channel: WaveChannel
    private let wavePattern: WavePattern
    private let control: SoundControl
    private let lengthCounterUnit: LengthCounterUnit
    private let lock = NSRecursiveLock()
    private var currentPhase: Float = 0
    /// This is a FIFO stack of queued signals to send to the audio node
    private var queuedSignals: [QueuedSignal] = []

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
        wavePattern: WavePattern,
        control: SoundControl,
        lengthCounterUnit: LengthCounterUnit
    ) {
        self.sampleRate = sampleRate
        self.channel = channel
        self.wavePattern = wavePattern
        self.control = control
        self.lengthCounterUnit = lengthCounterUnit
        currentVolume = control.getStereoVolume(for: channel.controlFlag)
    }

    public func makeSourceNode() -> AVAudioSourceNode {
        AVAudioSourceNode(renderBlock: createAudioRenderBlock(provider: self))
    }

    public func restart() {
        currentPhase = 0
    }

    public func generateSample() {
        let shift = channel.waveFrequency * twoPi / sampleRate
        currentPhase += shift
        let magnitude = getSignal(currentPhase: currentPhase)
        let signal = magnitude * amplitude
        let queuedSignal = (signal * currentVolume.leftVolume, signal * currentVolume.rightVolume)
        queuedSignals.append(queuedSignal)
    }

    public func soundControlDidUpdateRouting() {
        currentVolume = control.getStereoVolume(for: channel.controlFlag)
    }

    // MARK: - Helpers

    private func getSignal(currentPhase: Float) -> Float {
        let normalizedPhase = currentPhase / twoPi
        let sample = wavePattern.getSample(atNormalizedPhase: normalizedPhase)

        // value in the range -1.0 - 1.0
        let normalizedSignal = (Float(sample) / 0x0f) * 2 - 1
        return normalizedSignal
    }

    fileprivate func getQueuedSignal() -> QueuedSignal? {
        guard !queuedSignals.isEmpty else { return nil }
        return queuedSignals.removeFirst()
    }
}

// MARK: - Free helper functions

private func createAudioRenderBlock(provider: AudioDataProvider) -> AVAudioSourceNodeRenderBlock {
    return { isSilence, timestamp, frameCount, audioBufferList in
        let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
        for frame in 0..<Int(frameCount) {
            let nextSignal = provider.getQueuedSignal() ?? (0, 0)

            // Set the same value on left and right
            assert(buffers.count == 2, "There should only be two buffers representing left and right channels")
            for (buffer, signal) in zip(buffers, [nextSignal.left, nextSignal.right]) {
                let bufferPointer = UnsafeMutableBufferPointer<Float>(buffer)
                bufferPointer[frame] = Float(signal)
            }
        }
        return noErr
    }
}

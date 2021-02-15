import AVFoundation

public struct StereoSample {
    public let left: Float
    public let right: Float

    public static let zero = StereoSample(left: 0, right: 0)
}

private protocol AudioDataProvider {
    func popQueuedSamples(count: Int) -> [StereoSample]
}

public final class SourceNodeProvider: AudioDataProvider {
    private var queuedSamples: [StereoSample] = []
    private let lock = NSLock()

    public func makeSourceNode() -> AVAudioSourceNode {
        AVAudioSourceNode(renderBlock: createAudioRenderBlock(provider: self))
    }

    public func renderSample(_ sample: StereoSample) {
        defer { lock.unlock() }
        lock.lock()
        queuedSamples.append(sample)
    }

    // MARK: - AudioDataProvider

    fileprivate func popQueuedSamples(count: Int) -> [StereoSample] {
        let popCount = min(count, queuedSamples.count)
        guard popCount > 0 else { return [] }

        defer { lock.unlock() }
        lock.lock()
        return queuedSamples.removeAndReturnFirst(popCount)
    }
}

// MARK: - Free helper functions

private func createAudioRenderBlock(provider: AudioDataProvider) -> AVAudioSourceNodeRenderBlock {
    return { isSilence, timestamp, frameCount, audioBufferList in
        let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
        let samples = provider.popQueuedSamples(count: Int(frameCount))
        for frame in 0..<Int(frameCount) {
            let nextSample = samples.count > frame ? samples[frame] : .zero

            // Set the same value on left and right
            assert(buffers.count == 2, "There should only be two buffers representing left and right channels")
            for (buffer, sample) in zip(buffers, [nextSample.left, nextSample.right]) {
                let bufferPointer = UnsafeMutableBufferPointer<Float>(buffer)
                bufferPointer[frame] = Float(sample)
            }
        }
        return noErr
    }
}

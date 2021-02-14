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
    private let queue = DispatchQueue(
        label: "com.daltonclaybrook.GameBoy.SourceNodeProvider"
    )

    private var queuedSamples: [StereoSample] = []

    public func makeSourceNode() -> AVAudioSourceNode {
        AVAudioSourceNode(renderBlock: createAudioRenderBlock(provider: self))
    }

    public func renderSample(_ sample: StereoSample) {
        queue.sync {
            self.queuedSamples.append(sample)
        }
    }

    // MARK: - AudioDataProvider

    fileprivate func popQueuedSamples(count: Int) -> [StereoSample] {
        let popCount = min(count, queuedSamples.count)
        guard popCount > 0 else { return [] }

        var samples: [StereoSample] = []
        queue.sync {
            samples = self.queuedSamples.removeAndReturnFirst(popCount)
        }
        return samples
    }
}

// MARK: - Free helper functions

private var nilCount: UInt64 = 0
private var nonNilCount: UInt64 = 0
private func createAudioRenderBlock(provider: AudioDataProvider) -> AVAudioSourceNodeRenderBlock {
    return { isSilence, timestamp, frameCount, audioBufferList in
        let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
        let samples = provider.popQueuedSamples(count: Int(frameCount))
        for frame in 0..<Int(frameCount) {
            let nextSample = samples.count > frame ? samples[frame] : .zero
            if frame >= samples.count {
                nilCount += 1
                if nilCount % 100 == 0 {
                    print("nil count: \(nilCount), non-nil: \(nonNilCount)")
                }
            } else {
                nonNilCount += 1
            }

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

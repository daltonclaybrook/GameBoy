import AVFoundation

private protocol AudioDataProvider: AnyObject {
    var frequency: Float64 { get }
    var sampleRate: Float64 { get }
    var amplitude: Float64 { get }
    var countOfQueuedSamples: Int { get }
    var framesPerSecond: UInt64 { get set }

    func getSignal(currentPhase: inout Float64) -> Float64
    func getQueuedSignal() -> Float64?
    func flushQueuedSamples()
}

private let twoPi = 2 * Float64.pi

public final class WaveSourceNode: AudioSourceNode, AudioDataProvider {
    fileprivate let sampleRate: Float64

    private let channel: WaveChannel
    private let wavePattern: WavePattern
    private let control: SoundControl
    private let lengthCounterUnit: LengthCounterUnit
    private let lock = NSRecursiveLock()
    private var queuedResetCurrentPhase = false
    private var currentPhase: Float64 = 0
    /// This is a FIFO stack of queued signals to send to the audio node
    private var queuedSignals: [Float64] = []

    fileprivate var frequency: Float64 {
        Float64(channel.waveFrequency)
    }

    fileprivate var amplitude: Float64 {
        guard control.isSoundEnabled &&
                lengthCounterUnit.isAllowingSound &&
                channel.isWaveEnabled
        else { return 0 }
        return Float64(channel.volume.percent) * 0.1
    }

    public init(
        sampleRate: Float,
        channel: WaveChannel,
        wavePattern: WavePattern,
        control: SoundControl,
        lengthCounterUnit: LengthCounterUnit
    ) {
        self.sampleRate = Float64(sampleRate)
        self.framesPerSecond = UInt64(sampleRate)
        self.channel = channel
        self.wavePattern = wavePattern
        self.control = control
        self.lengthCounterUnit = lengthCounterUnit
    }

    public func makeSourceNode() -> AVAudioSourceNode {
        AVAudioSourceNode(renderBlock: createAudioRenderBlock(provider: self))
    }

    var countOfWaves = 0
    public func restart() {
        countOfWaves += 1
//        printDate("starting wave: \(countOfWaves)")
        setQueuedResetCurrentPhase(true)

//        if countOfWaves == 114 {
//            printDate("one before pikachu...")
//            wavePattern.shouldPrint = true
//        }
//        if countOfWaves == 115 {
//            // This is the pikachu wave
//            printDate("starting pikachu...")
//            let waveData = Data(wavePattern.samples)
//            let fileURL = URL(fileURLWithPath: "/Users/daltonclaybrook/Desktop/pika_pre_wave_pattern.bin")
//            try! waveData.write(to: fileURL, options: .atomic)
//        }
//        if countOfWaves == 116 {
//            printDate("pikachu over.")
//            wavePattern.shouldPrint = false
//            let waveData = Data(wavePattern.samples)
//            let fileURL = URL(fileURLWithPath: "/Users/daltonclaybrook/Desktop/pika_wave_pattern.bin")
//            try! waveData.write(to: fileURL, options: .atomic)
//        }
    }

    var lastPushDate = Date()
    var pushCounter: UInt64 = 0

    public func pushNewSample() {
        pushCounter += 1
        let currentDate = Date()
        if currentDate.timeIntervalSince(lastPushDate) >= 1 {
            lastPushDate = currentDate
            print("pushes per second: \(pushCounter)")
            pushCounter = 0
        }

        let shift = frequency * twoPi / sampleRate
        currentPhase += shift
        let magnitude = getSignal(currentPhase: &currentPhase)
        let signal = magnitude * amplitude
        queuedSignals.append(signal)
    }

    // MARK: - Helpers

    public fileprivate(set) var framesPerSecond: UInt64

    fileprivate var countOfQueuedSamples: Int {
        queuedSignals.count
    }

    fileprivate func getSignal(currentPhase: inout Float64) -> Float64 {
        if queuedResetCurrentPhase {
            setQueuedResetCurrentPhase(false)
            currentPhase = 0
        }

        // phase range 0..<1
        let normalizedPhase = currentPhase / twoPi
        let sample = wavePattern.getSample(atNormalizedPhase: normalizedPhase)

        // value in the range -1.0 - 1.0
        let normalizedSignal = (sample / 0x0f) * 2 - 1
        return normalizedSignal
    }

    fileprivate func getQueuedSignal() -> Float64? {
        guard !queuedSignals.isEmpty else { return nil }
        return queuedSignals.removeFirst()
    }

    func flushQueuedSamples() {
        queuedSignals = []
    }

    private func setQueuedResetCurrentPhase(_ reset: Bool) {
        lock.lock()
        defer { lock.unlock() }
        queuedResetCurrentPhase = reset
    }
}

// MARK: - Free helper functions

var lastDate = Date()
var counter: UInt64 = 0

private func createAudioRenderBlock(provider: AudioDataProvider) -> AVAudioSourceNodeRenderBlock {
    return { isSilence, timestamp, frameCount, audioBufferList in
        let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
        for frame in 0..<Int(frameCount) {
            let nextSignal = provider.getQueuedSignal() ?? 0

            // Set the same value on all channels (due to the inputFormat we have only 1 channel though).
            for buffer in buffers {
                let bufferPointer = UnsafeMutableBufferPointer<Float>(buffer)
                bufferPointer[frame] = Float(nextSignal)
            }
        }

        counter += 1
        let currentDate = Date()
        if currentDate.timeIntervalSince(lastDate) >= 1 {
            lastDate = currentDate
            print("frames per second: \(UInt64(frameCount) * counter), leftovers: \(provider.countOfQueuedSamples)")
            provider.framesPerSecond = UInt64(frameCount) * counter
            counter = 0
        }
        return noErr
    }
}

private func printDate(_ string: String) {
    let dateString = String(format: "%.2f", Date().timeIntervalSince1970)
    print("\(dateString): \(string)")
}

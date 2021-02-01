import AVFoundation

/// Audio processing unit for the Game Boy
public final class APU: MemoryAddressable {
    struct Registers {
        fileprivate static let channel1Range: ClosedRange<Address> = 0xff10...0xff14
        fileprivate static let channel2Range: ClosedRange<Address> = 0xff15...0xff19
        fileprivate static let channel3Range: ClosedRange<Address> = 0xff1a...0xff1e
        fileprivate static let channel4Range: ClosedRange<Address> = 0xff1f...0xff23
        fileprivate static let controlRange: ClosedRange<Address> = 0xff24...0xff26
        fileprivate static let wavePatternRange: ClosedRange<Address> = 0xff30...0xff3f

        // These two ranges are used by `IO` to route reads/writes to this object
        static let lowerRange: ClosedRange<Address> = channel1Range.lowerBound...controlRange.upperBound
        static var upperRange: ClosedRange<Address> {
            wavePatternRange
        }
    }

    private let queue = DispatchQueue(
        label: "com.daltonclaybrook.GameBoy.APU",
        qos: .userInteractive
    )
    private var timer: DispatchSourceTimer?
    private let timeInterval: TimeInterval = 1.0 / 512.0 // 512 Hz

    private let control = SoundControl()

    // Channel 1 + associated units. Todo: consider abstracting this a bit better
    // to enable reusable APIs between different channels with the same units
    private let channel1 = Channel1()
    private let sweepUnit: SweepUnit
    private let lengthCounterUnit: LengthCounterUnit
    private let volumeEnvelopeUnit: VolumeEnvelopeUnit

    private let audioEngine = AVAudioEngine()
    private let twoPi = 2 * Float.pi

    init() {
        sweepUnit = SweepUnit(channel1: channel1)
        lengthCounterUnit = LengthCounterUnit(channel1: channel1)
        volumeEnvelopeUnit = VolumeEnvelopeUnit(channel1: channel1)
        channel1.delegate = self
//        @param isSilence
//            The client may use this flag to indicate that the buffer it vends contains only silence.
//            The receiver of the buffer can then use the flag as a hint as to whether the buffer needs
//            to be processed or not.
//            Note that because the flag is only a hint, when setting the silence flag, the originator of
//            a buffer must also ensure that it contains silence (zeroes).
//        @param timestamp
//            The HAL time at which the audio data will be rendered. If there is a sample rate conversion
//            or time compression/expansion downstream, the sample time will not be valid.
//        @param frameCount
//            The number of sample frames of audio data requested.
//        @param outputData
//            The output data.

        setupAudioNode()
    }

    public func write(byte: Byte, to address: Address) {
        switch address {
        case Registers.channel1Range:
            channel1.write(byte: byte, to: address)
        case Registers.controlRange:
            control.write(byte: byte, to: address)
        default:
            break // todo: implement
        }

    }

    public func read(address: Address) -> Byte {
        switch address {
        case Registers.channel1Range:
            return channel1.read(address: address)
        case Registers.controlRange:
            return control.read(address: address)
        default:
            return 0xff // todo: implement
        }
    }

    func start() {
        stop()
        let timer = DispatchSource.makeTimerSource(queue: queue)
        self.timer = timer

        var currentStep: UInt64 = 0
        timer.setEventHandler {
            self.advanceFrameSequencer(step: currentStep)
            currentStep += 1
        }
        timer.schedule(deadline: .now(), repeating: timeInterval)
        timer.resume()

        do {
            try audioEngine.start()
        } catch let error {
            print("error starting audio engine: \(error.localizedDescription)")
            stop()
        }
    }

    func stop() {
        timer?.setEventHandler(handler: nil)
        timer?.cancel()
        timer = nil
        audioEngine.stop()
    }

    // MARK: - Helpers

    private func setupAudioNode() {
        let mainMixer = audioEngine.mainMixerNode
        let output = audioEngine.outputNode
        let outputFormat = output.inputFormat(forBus: 0)
        let sampleRate = Float(outputFormat.sampleRate)

        let inputFormat = AVAudioFormat(
            commonFormat: outputFormat.commonFormat,
            sampleRate: outputFormat.sampleRate,
            channels: 1, // should eventually support two channels
            interleaved: outputFormat.isInterleaved
        )

        var currentPhase: Float = 0
        let node = AVAudioSourceNode { [weak self] isSilence, timestamp, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return -1 }

            // The interval by which we advance the phase each frame.
            let frequency = self.channel1.frequency
            let phaseIncrement = (self.twoPi / sampleRate) * frequency
            let amplitude = self.getCurrentAmplitudeForChannel1()

            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                // Get signal value for this frame at time.
                let signal = self.getSignalForChannel1(currentPhase: currentPhase)
                let value = signal * amplitude
                // Advance the phase for the next frame.
                currentPhase += phaseIncrement
                if currentPhase >= self.twoPi {
                    currentPhase -= self.twoPi
                }
                if currentPhase < 0.0 {
                    currentPhase += self.twoPi
                }
                // Set the same value on all channels (due to the inputFormat we have only 1 channel though).
                for buffer in buffers {
                    let bufferPointer = UnsafeMutableBufferPointer<Float>(buffer)
                    bufferPointer[frame] = value
                }
            }

            return noErr
        }

        audioEngine.attach(node)
        audioEngine.connect(node, to: mainMixer, format: inputFormat)
        audioEngine.connect(mainMixer, to: output, format: outputFormat)
        mainMixer.outputVolume = 0.5
    }

    private func getCurrentAmplitudeForChannel1() -> Float {
        guard lengthCounterUnit.channelIsEnabled else { return 0 }
        return volumeEnvelopeUnit.normalizedVolume
    }

    private func getSignalForChannel1(currentPhase: Float) -> Float {
        let waveform = channel1.waveDuty.waveform
        let index = Int((currentPhase / twoPi) * Float(waveform.count))
        return waveform[index]
    }

    private func advanceFrameSequencer(step: UInt64) {
        if step % 2 == 0 {
            lengthCounterUnit.clockTick()
        }
        if (step + 1) % 8 == 0 {
            volumeEnvelopeUnit.clockTick()
        }
        if (step + 2) % 4 == 0 {
            sweepUnit.clockTick()
        }
    }
}

extension APU: Channel1Delegate {
    public func channel1ShouldRestart(_ channel1: Channel1) {
        queue.async { [sweepUnit, volumeEnvelopeUnit] in
            sweepUnit.restart()
            volumeEnvelopeUnit.restart()
        }
    }

    public func channel1(_ channel1: Channel1, loadedSoundLength soundLength: UInt8) {
        queue.async { [lengthCounterUnit] in
            lengthCounterUnit.load(soundLength: soundLength)
        }
    }
}

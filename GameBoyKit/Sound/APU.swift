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
    private let wavePattern = WavePattern()

    private let channelDriver1: ChannelDriver
    private let channelDriver2: ChannelDriver
    private let channelDriver3: ChannelDriver

    private var allDrivers: [ChannelDriver] {
        [channelDriver1, channelDriver2, channelDriver3]
    }

    private let audioEngine = AVAudioEngine()

    init() {
        let mainMixer = audioEngine.mainMixerNode
        let output = audioEngine.outputNode
        let outputFormat = output.inputFormat(forBus: 0)
        let factory = ChannelFactory(
            control: control,
            queue: queue,
            sampleRate: Float(outputFormat.sampleRate)
        )

        channelDriver1 = factory.makeChannel1()
        channelDriver2 = factory.makeChannel2()
        channelDriver3 = factory.makeChannel3(wavePattern: wavePattern)
        control.delegate = self
        setupAudioEngine(mainMixer: mainMixer, output: output, outputFormat: outputFormat)
    }

    public func write(byte: Byte, to address: Address) {
        switch address {
        case Registers.channel1Range:
            channelDriver1.channel.write(byte: byte, to: address)
        case Registers.channel2Range:
            channelDriver2.channel.write(byte: byte, to: address)
        case Registers.channel3Range:
            channelDriver3.channel.write(byte: byte, to: address)
        case Registers.controlRange:
            control.write(byte: byte, to: address)
        case Registers.wavePatternRange:
            wavePattern.write(byte: byte, to: address)
        default:
            break // todo: implement
        }
    }

    public func read(address: Address) -> Byte {
        switch address {
        case Registers.channel1Range:
            return channelDriver1.channel.read(address: address)
        case Registers.channel2Range:
            return channelDriver2.channel.read(address: address)
        case Registers.channel3Range:
            return channelDriver3.channel.read(address: address)
        case Registers.controlRange:
            return control.read(address: address)
        case Registers.wavePatternRange:
            return wavePattern.read(address: address)
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

    private func setupAudioEngine(mainMixer: AVAudioMixerNode, output: AVAudioOutputNode, outputFormat: AVAudioFormat) {
        let inputFormat = AVAudioFormat(
            commonFormat: outputFormat.commonFormat,
            sampleRate: outputFormat.sampleRate,
            channels: 1, // should eventually support two channels
            interleaved: outputFormat.isInterleaved
        )

        allDrivers.forEach { driver in
            let sourceNode = driver.sourceNode.makeSourceNode()
            audioEngine.attach(sourceNode)
            audioEngine.connect(sourceNode, to: mainMixer, format: inputFormat)
        }

        audioEngine.connect(mainMixer, to: output, format: outputFormat)
        mainMixer.outputVolume = 0.5
    }

    /// This function is called @ 512 Hz
    private func advanceFrameSequencer(step: UInt64) {
        if step % 2 == 0 { // 256 Hz
            allDrivers.forEach { $0.lengthCounterUnit?.clockTick() }
        }
        if (step + 1) % 8 == 0 { // 64 Hz
            allDrivers.forEach { $0.volumeEnvelopeUnit?.clockTick() }
        }
        if (step + 2) % 4 == 0 { // 128 Hz
            allDrivers.forEach { $0.sweepUnit?.clockTick() }
        }
    }
}

extension APU: SoundControlDelegate {
    public func soundControlDidStopAllSound(_ control: SoundControl) {
        queue.async { [allDrivers] in
            allDrivers.forEach { $0.reset() }
        }
    }
}

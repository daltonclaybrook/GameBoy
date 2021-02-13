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

    private var mCycles: Cycles = 0
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
        do {
            try audioEngine.start()
        } catch let error {
            print("error starting audio engine: \(error.localizedDescription)")
            stop()
        }
    }

    func stop() {
        audioEngine.stop()
    }

    /// Called once per m-cycle
    func emulate() {
        mCycles += 1
        let tickLengthCounter = mCycles % (Clock.effectiveMachineSpeed / 256) == 0
        let tickSweep = mCycles % (Clock.effectiveMachineSpeed / 128) == 0
        let tickVolumeEnvelope = mCycles % (Clock.effectiveMachineSpeed / 64) == 0

        allDrivers.forEach { driver in
            if tickLengthCounter {
                driver.lengthCounterUnit?.clockTick()
            }
            if tickVolumeEnvelope {
                driver.volumeEnvelopeUnit?.clockTick()
            }
            if tickSweep {
                driver.sweepUnit?.clockTick()
            }
        }
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
            let sourceNode = driver.engineSourceNode
            audioEngine.attach(sourceNode)
            audioEngine.connect(sourceNode, to: mainMixer, format: inputFormat)
        }

        audioEngine.connect(mainMixer, to: output, format: outputFormat)
        update(mainMixer: mainMixer, with: control.masterStereoVolume)
    }

    private func update(mainMixer: AVAudioMixerNode, with masterStereoVolume: MasterStereoVolume) {
        // 0.5 seems to be a good multiplier at the moment
        mainMixer.outputVolume = masterStereoVolume.volume * 0.5
        mainMixer.pan = masterStereoVolume.pan
    }
}

extension APU: SoundControlDelegate {
    public func soundControlDidStopAllSound(_ control: SoundControl) {
        allDrivers.forEach { $0.reset() }
    }

    public func soundControl(_ control: SoundControl, didUpdate masterStereoVolume: MasterStereoVolume) {
        update(mainMixer: audioEngine.mainMixerNode, with: masterStereoVolume)
    }

    public func soundControlDidUpdateChannelRouting(_ control: SoundControl) {
        allDrivers.forEach { driver in
            driver.soundControlDidUpdateRouting()
        }
    }
}

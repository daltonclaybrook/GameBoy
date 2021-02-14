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
    /// Measured in Hz
    private let sampleRate: UInt64
    /// We push n samples at 441 Hz for a sample rate of `n * 441`. This is usually 44.1 KHz.
    private let samplePeriod: UInt64 = 441
    /// If the sample rate is 44.1 KHz, this value is 100.
    private let samplesPerPeriod: UInt64

    private let cyclesPerSample: Cycles
    private let control = SoundControl()
    private let wavePattern = WavePattern()
    private let sourceNodeProvider = SourceNodeProvider()

    private let channelDriver1: ChannelDriver
    private let channelDriver2: ChannelDriver
    private let channelDriver3: ChannelDriver

    private var allDrivers: [ChannelDriver] {
        [channelDriver1, channelDriver2, channelDriver3]
    }
//    private var allDrivers: [ChannelDriver] {
//        [channelDriver1]
//    }

    private let audioEngine = AVAudioEngine()

    init() {
        let mainMixer = audioEngine.mainMixerNode
        let output = audioEngine.outputNode
        let outputFormat = output.inputFormat(forBus: 0)
        let factory = ChannelFactory(
            control: control,
            sampleRate: Float(outputFormat.sampleRate)
        )

        sampleRate = UInt64(outputFormat.sampleRate)
        samplesPerPeriod = sampleRate / samplePeriod
        cyclesPerSample = Clock.effectiveMachineSpeed / sampleRate

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
        emulateAudioUnitsIfNecessary()
        createNewSamplesIfNecessary()
    }

    // MARK: - Helpers

    private func setupAudioEngine(mainMixer: AVAudioMixerNode, output: AVAudioOutputNode, outputFormat: AVAudioFormat) {
        let inputFormat = AVAudioFormat(
            commonFormat: outputFormat.commonFormat,
            sampleRate: outputFormat.sampleRate,
            channels: 2, // left and right
            interleaved: outputFormat.isInterleaved
        )

        let sourceNode = sourceNodeProvider.makeSourceNode()
        audioEngine.attach(sourceNode)
        audioEngine.connect(sourceNode, to: mainMixer, format: inputFormat)

        audioEngine.connect(mainMixer, to: output, format: outputFormat)
        update(mainMixer: mainMixer, with: control.masterStereoVolume)
    }

    private func update(mainMixer: AVAudioMixerNode, with masterStereoVolume: MasterStereoVolume) {
        // 0.5 seems to be a good multiplier at the moment
        mainMixer.outputVolume = masterStereoVolume.masterVolume * 0.5
        mainMixer.pan = masterStereoVolume.pan
    }

    private func emulateAudioUnitsIfNecessary() {
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

//    private var samplesPushedThisPeriod: UInt64 = 0
//    private func createNewSamplesIfNecessary() {
//        let cyclesPerSamplePeriod = UInt64((Double(Clock.effectiveMachineSpeed) / Double(samplePeriod)).rounded(.up))
//        if mCycles % cyclesPerSamplePeriod == 0 {
//            samplesPushedThisPeriod = 0
//        }
//
//        if samplesPushedThisPeriod < samplesPerPeriod && mCycles % cyclesPerSample == 0 {
//            samplesPushedThisPeriod += 1
//            allDrivers.forEach { $0.generateSample() }
//        }
//    }

    private var samplesPushedThisPeriod: UInt64 = 0
    private func createNewSamplesIfNecessary() {
        if mCycles % Clock.effectiveMachineSpeed == 0 {
            samplesPushedThisPeriod = 0
        }
        if samplesPushedThisPeriod < sampleRate && mCycles % cyclesPerSample == 0 {
            samplesPushedThisPeriod += 1

            let samples = allDrivers.map { $0.generateSample() }
            let leftAverage = samples.reduce(0.0 as Float) { $0 + $1.left } / Float(samples.count)
            let rightAverage = samples.reduce(0.0 as Float) { $0 + $1.right } / Float(samples.count)
            let sample = StereoSample(left: leftAverage, right: rightAverage)
            sourceNodeProvider.renderSample(sample)
        }
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

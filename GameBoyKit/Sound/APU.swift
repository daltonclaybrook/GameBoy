import AVFoundation

/// Audio processing unit for the Game Boy
public final class APU: MemoryAddressable, EmulationStepType {
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

    public let stepRate: StepRate = .alwaysNormalSpeed

    private var mCycles: Cycles = 0
    /// Measured in Hz
    private let sampleRate: UInt64
    /// We push n samples at 441 Hz for a sample rate of `n * 441`. This is usually 44.1 KHz.
    private let samplePeriod: UInt64 = 441
    /// If the sample rate is 44.1 KHz, this value is 100.
    private let samplesPerPeriod: UInt64

    private let cyclesPerSample: Cycles
    private let cyclesPerSamplePeriod: Cycles
    private let control = SoundControl()
    private let wavePattern = WavePattern()
    private let sourceNodeProvider = SourceNodeProvider()
    private let audioEngine = AVAudioEngine()

    private let channel1Driver: ChannelDriver
    private let channel2Driver: ChannelDriver
    private let channel3Driver: ChannelDriver
    private let channel4Driver: ChannelDriver

    private var allDrivers: [ChannelDriver] {
        [channel1Driver, channel2Driver, channel3Driver, channel4Driver]
    }

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
        cyclesPerSample = Clock.machineSpeed / sampleRate
        cyclesPerSamplePeriod = UInt64((Double(Clock.machineSpeed) / Double(samplePeriod)).rounded(.up))

        channel1Driver = factory.makeChannel1()
        channel2Driver = factory.makeChannel2()
        channel3Driver = factory.makeChannel3(wavePattern: wavePattern)
        channel4Driver = factory.makeChannel4()
        control.delegate = self
        setupAudioEngine(mainMixer: mainMixer, output: output, outputFormat: outputFormat)
    }

    public func write(byte: Byte, to address: Address) {
        switch address {
        case Registers.channel1Range:
            channel1Driver.channel.write(byte: byte, to: address)
        case Registers.channel2Range:
            channel2Driver.channel.write(byte: byte, to: address)
        case Registers.channel3Range:
            channel3Driver.channel.write(byte: byte, to: address)
        case Registers.channel4Range:
            channel4Driver.channel.write(byte: byte, to: address)
        case Registers.controlRange:
            control.write(byte: byte, to: address)
        case Registers.wavePatternRange:
            wavePattern.write(byte: byte, to: address)
        default:
            fatalError("Invalid address")
        }
    }

    public func read(address: Address) -> Byte {
        switch address {
        case Registers.channel1Range:
            return channel1Driver.channel.read(address: address)
        case Registers.channel2Range:
            return channel2Driver.channel.read(address: address)
        case Registers.channel3Range:
            return channel3Driver.channel.read(address: address)
        case Registers.channel4Range:
            return channel4Driver.channel.read(address: address)
        case Registers.controlRange:
            return control.read(address: address)
        case Registers.wavePatternRange:
            return wavePattern.read(address: address)
        default:
            fatalError("Invalid address")
        }
    }

    func start() {
        stop()
        do {
            try audioEngine.start()
        } catch let error {
            assertionFailure("error starting audio engine: \(error.localizedDescription)")
            stop()
        }
    }

    func stop() {
        audioEngine.stop()
    }

    /// Called once per m-cycle
    public func emulateStep() {
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
        update(mainMixer: mainMixer, with: control.stereoVolume)
    }

    private func update(mainMixer: AVAudioMixerNode, with stereoVolume: StereoVolume) {
        // 0.5 seems to be a good multiplier at the moment
        mainMixer.outputVolume = stereoVolume.masterVolume * 0.5
        mainMixer.pan = stereoVolume.pan
    }

    private func emulateAudioUnitsIfNecessary() {
        let tickLengthCounter = mCycles % (Clock.machineSpeed / 256) == 0
        let tickSweep = mCycles % (Clock.machineSpeed / 128) == 0
        let tickVolumeEnvelope = mCycles % (Clock.machineSpeed / 64) == 0

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

    private var samplesPushedThisPeriod: UInt64 = 0
    private func createNewSamplesIfNecessary() {
        if mCycles % cyclesPerSamplePeriod == 0 {
            samplesPushedThisPeriod = 0
        }

        if samplesPushedThisPeriod < samplesPerPeriod && mCycles % cyclesPerSample == 0 {
            samplesPushedThisPeriod += 1
            renderSample()
        }
    }

    private func renderSample() {
        typealias Sums = (left: Float, right: Float)
        let sums = allDrivers.reduce((0, 0) as Sums) { sums, driver in
            let sample = driver.generateSample()
            return (sums.left + sample.left, sums.right + sample.right)
        }
        let count = Float(allDrivers.count)
        let sample = StereoSample(left: sums.left / count, right: sums.right / count)
        sourceNodeProvider.renderSample(sample)
    }
}

extension APU: SoundControlDelegate {
    public func soundControlDidStopAllSound(_ control: SoundControl) {
        allDrivers.forEach { $0.reset() }
    }

    public func soundControl(_ control: SoundControl, didUpdate stereoVolume: StereoVolume) {
        update(mainMixer: audioEngine.mainMixerNode, with: stereoVolume)
    }

    public func soundControlDidUpdateChannelRouting(_ control: SoundControl) {
        allDrivers.forEach { driver in
            driver.soundControlDidUpdateRouting()
        }
    }
}

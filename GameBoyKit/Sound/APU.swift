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

    private let channel1 = Channel1()
    private let control = SoundControl()

    init() {
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
//        let node = AVAudioSourceNode { (isSilence, timestamp, frameCount, outputData) -> OSStatus in
//            return noErr
//        }
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
    }

    func stop() {
        timer?.setEventHandler(handler: nil)
        timer?.cancel()
        timer = nil
    }

    // MARK: - Helpers

    private func advanceFrameSequencer(step: UInt64) {
        print("step: \(step)")
        if step % 2 == 0 {
            // length counter
            print("length counter clock")
        }
        if (step + 1) % 8 == 0 {
            // volume envelope
            print("volume envelope clock")
        }
        if (step + 2) % 4 == 0 {
            // sweep
            print("sweep clock")
        }
    }
}

extension APU: Channel1Delegate {
    public func channel1ShouldRestart(_ channel1: Channel1) {
        // restart
    }

    public func channel1(_ channel1: Channel1, loadedSoundLength soundLength: UInt8) {
        // update volume envelope
    }
}

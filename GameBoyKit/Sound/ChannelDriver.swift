/// Objects of this type manage a channel and its associated audio units.
public final class ChannelDriver {
    public let channel: Channel
    private let control: SoundControl
    private let sampleProvider: SampleProviding

    // Units
    var sweepUnit: SweepUnit?
    var lengthCounterUnit: LengthCounterUnit?
    var volumeEnvelopeUnit: VolumeEnvelopeUnit?

    public init(channel: Channel, control: SoundControl, sampleProvider: SampleProviding) {
        self.channel = channel
        self.control = control
        self.sampleProvider = sampleProvider
        channel.delegate = self
    }

    public func reset() {
        channel.reset()
        sweepUnit?.reset()
        lengthCounterUnit?.reset()
        volumeEnvelopeUnit?.reset()
    }

    public func soundControlDidUpdateRouting() {
        sampleProvider.soundControlDidUpdateRouting()
    }

    public func generateSample() -> StereoSample {
        sampleProvider.generateSample()
    }
}

extension ChannelDriver: ChannelDelegate {
    public func channelShouldRestart(_ channel: Channel) {
        control.enabledChannels.insert(channel.controlFlag)
        sweepUnit?.restart()
        lengthCounterUnit?.restart()
        volumeEnvelopeUnit?.restart()
        sampleProvider.restart()
    }

    public func channel(_ channel: Channel, loadedSoundLength soundLength: UInt8) {
        lengthCounterUnit?.load(soundLength: soundLength)
    }
}

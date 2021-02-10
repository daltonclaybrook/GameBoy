/// Objects of this type manage a channel and its associated audio units.
public final class ChannelDriver {
    public let channel: Channel
    public let sourceNode: AudioSourceNode

    private let control: SoundControl

    // Units
    var sweepUnit: SweepUnit?
    var lengthCounterUnit: LengthCounterUnit?
    var volumeEnvelopeUnit: VolumeEnvelopeUnit?

    public init(channel: Channel, control: SoundControl, sourceNode: AudioSourceNode) {
        self.channel = channel
        self.control = control
        self.sourceNode = sourceNode
        channel.delegate = self
    }

    public func reset() {
        channel.reset()
        sweepUnit?.reset()
        lengthCounterUnit?.reset()
        volumeEnvelopeUnit?.reset()
    }
}

extension ChannelDriver: ChannelDelegate {
    public func channelShouldRestart(_ channel: Channel) {
        control.enabledChannels.insert(channel.controlFlag)
        sweepUnit?.restart()
        lengthCounterUnit?.restart()
        volumeEnvelopeUnit?.restart()
        sourceNode.restart()
    }

    public func channel(_ channel: Channel, loadedSoundLength soundLength: UInt8) {
        lengthCounterUnit?.load(soundLength: soundLength)
    }
}

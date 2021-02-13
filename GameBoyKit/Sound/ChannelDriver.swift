import AVFoundation

/// Objects of this type manage a channel and its associated audio units.
public final class ChannelDriver {
    public let channel: Channel
    public let engineSourceNode: AVAudioSourceNode

    private let control: SoundControl
    private let sourceNode: AudioSourceNode

    // Units
    var sweepUnit: SweepUnit?
    var lengthCounterUnit: LengthCounterUnit?
    var volumeEnvelopeUnit: VolumeEnvelopeUnit?

    public init(channel: Channel, control: SoundControl, sourceNode: AudioSourceNode) {
        self.channel = channel
        self.control = control
        self.sourceNode = sourceNode
        self.engineSourceNode = sourceNode.makeSourceNode()
        channel.delegate = self
        soundControlDidUpdateRouting() // determine initial pan
    }

    public func reset() {
        channel.reset()
        sweepUnit?.reset()
        lengthCounterUnit?.reset()
        volumeEnvelopeUnit?.reset()
    }

    public func soundControlDidUpdateRouting() {
        let stereoVolume = control.getStereoVolume(for: channel.controlFlag)
        engineSourceNode.pan = stereoVolume.pan
        engineSourceNode.volume = stereoVolume.volume
    }

    public func createSample() {
        sourceNode.pushNewSample()
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

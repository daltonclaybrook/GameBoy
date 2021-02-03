/// Objects of this type manage a channel and its associated audio units.
public final class ChannelDriver {
    public let channel: Channel

    private let control: SoundControl
    private let queue: DispatchQueue

    // Units
    var sweepUnit: SweepUnit?
    var lengthCounterUnit: LengthCounterUnit?
    var volumeEnvelopeUnit: VolumeEnvelopeUnit?

    public init(channel: Channel, control: SoundControl, queue: DispatchQueue) {
        self.channel = channel
        self.control = control
        self.queue = queue
        channel.delegate = self
    }

    public func reset() {
        channel.reset()
        sweepUnit?.reset()
        lengthCounterUnit?.reset()
        volumeEnvelopeUnit?.reset()
    }

    public func makeAudioSourceNode(sampleRate: Float) -> AudioSourceNode? {
        guard let lengthCounterUnit = lengthCounterUnit,
              let volumeEnvelopeUnit = volumeEnvelopeUnit,
              let channel = channel as? (FrequencyChannel & WaveDutyChannel)
        else { return nil }
        return AudioSourceNode(
            sampleRate: sampleRate,
            channel: channel,
            control: control,
            lengthCounterUnit: lengthCounterUnit,
            volumeEnvelopeUnit: volumeEnvelopeUnit
        )
    }
}

extension ChannelDriver: ChannelDelegate {
    public func channelShouldRestart(_ channel: Channel) {
        queue.async { [control, sweepUnit, volumeEnvelopeUnit] in
            control.enabledChannels.insert(channel.controlFlag)
            sweepUnit?.restart()
            volumeEnvelopeUnit?.restart()
        }
    }

    public func channel(_ channel1: Channel, loadedSoundLength soundLength: UInt8) {
        queue.async { [lengthCounterUnit] in
            lengthCounterUnit?.load(soundLength: soundLength)
        }
    }
}

public struct ChannelFactory {
    let control: SoundControl
    let sampleRate: Float

    func makeChannel1() -> ChannelDriver {
        let channel = SquareChannel1()
        let lengthCounterUnit = LengthCounterUnit(channel: channel, control: control)
        let volumeEnvelopeUnit = VolumeEnvelopeUnit(channel: channel)

        let driver = ChannelDriver(
            channel: channel,
            control: control,
            sampleProvider: SquareSampleProvider(
                sampleRate: sampleRate,
                channel: channel,
                control: control,
                lengthCounterUnit: lengthCounterUnit,
                volumeEnvelopeUnit: volumeEnvelopeUnit
            )
        )

        driver.sweepUnit = SweepUnit(channel: channel)
        driver.lengthCounterUnit = lengthCounterUnit
        driver.volumeEnvelopeUnit = volumeEnvelopeUnit
        return driver
    }

    func makeChannel2() -> ChannelDriver {
        let channel = SquareChannel2()
        let lengthCounterUnit = LengthCounterUnit(channel: channel, control: control)
        let volumeEnvelopeUnit = VolumeEnvelopeUnit(channel: channel)

        let driver = ChannelDriver(
            channel: channel,
            control: control,
            sampleProvider: SquareSampleProvider(
                sampleRate: sampleRate,
                channel: channel,
                control: control,
                lengthCounterUnit: lengthCounterUnit,
                volumeEnvelopeUnit: volumeEnvelopeUnit
            )
        )

        driver.lengthCounterUnit = lengthCounterUnit
        driver.volumeEnvelopeUnit = volumeEnvelopeUnit
        return driver
    }

    func makeChannel3(wavePattern: WavePattern) -> ChannelDriver {
        let channel = WaveChannel()
        let lengthCounterUnit = LengthCounterUnit(channel: channel, control: control)

        let driver = ChannelDriver(
            channel: channel,
            control: control,
            sampleProvider: WaveSampleProvider(
                sampleRate: sampleRate,
                channel: channel,
                control: control,
                wavePattern: wavePattern,
                lengthCounterUnit: lengthCounterUnit
            )
        )

        driver.lengthCounterUnit = lengthCounterUnit
        return driver
    }

    func makeChannel4() -> ChannelDriver {
        let channel = NoiseChannel()
        let lengthCounterUnit = LengthCounterUnit(channel: channel, control: control)
        let volumeEnvelopeUnit = VolumeEnvelopeUnit(channel: channel)

        let driver = ChannelDriver(
            channel: channel,
            control: control,
            sampleProvider: NoiseSampleProvider(
                sampleRate: sampleRate,
                channel: channel,
                control: control,
                lengthCounterUnit: lengthCounterUnit,
                volumeEnvelopeUnit: volumeEnvelopeUnit
            )
        )

        driver.lengthCounterUnit = lengthCounterUnit
        driver.volumeEnvelopeUnit = volumeEnvelopeUnit
        return driver
    }
}

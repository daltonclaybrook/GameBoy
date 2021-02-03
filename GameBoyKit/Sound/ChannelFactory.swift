public struct ChannelFactory {
    let control: SoundControl
    let queue: DispatchQueue

    func makeChannel1() -> ChannelDriver {
        let channel = SquareChannel1()
        let driver = ChannelDriver(
            channel: channel,
            control: control,
            queue: queue
        )
        driver.sweepUnit = SweepUnit(channel: channel)
        driver.lengthCounterUnit = LengthCounterUnit(channel: channel, control: control)
        driver.volumeEnvelopeUnit = VolumeEnvelopeUnit(channel: channel)
        return driver
    }

    func makeChannel2() -> ChannelDriver {
        let channel = SquareChannel2()
        let driver = ChannelDriver(
            channel: channel,
            control: control,
            queue: queue
        )
        driver.lengthCounterUnit = LengthCounterUnit(channel: channel, control: control)
        driver.volumeEnvelopeUnit = VolumeEnvelopeUnit(channel: channel)
        return driver
    }
}

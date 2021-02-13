import Foundation

/// Square channel is an abstract base class that should not be
/// instantiated. It is the superclass of the two square channels.
public class SquareChannel:
    LockableChannel,
    WaveDutyChannel,
    LengthChannel,
    VolumeEnvelopeChannel,
    FrequencyChannel
{
    public weak var delegate: ChannelDelegate?
    public var waveDuty: WaveDuty = .fiftyPercent
    public var soundLength: UInt8 = 0
    public var isSoundLengthEnabled = false
    public var combinedFrequencyRegister: UInt16 = 0x00
    public var volumeEnvelopeRegister: Byte = 0x00
    public let lock = NSRecursiveLock()

    public var firstRegisterAddress: Address {
        fatalError("This property must be implemented in a subclass")
    }
    public var controlFlag: SoundControl.ChannelFlags {
        fatalError("This property must be implemented in a subclass")
    }

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        waveDuty = .fiftyPercent
        soundLength = 0
        isSoundLengthEnabled = false
        combinedFrequencyRegister = 0
        volumeEnvelopeRegister = 0
    }

    public func writeSweepInfoOrWaveEnabled(byte: Byte) {
        // no-op
    }

    public func getSweepInfoOrWaveEnabled() -> Byte {
        // no-op
        return 0
    }
}

// MARK: - Square Channel 1

public final class SquareChannel1: SquareChannel, SweepChannel {
    public var sweepRegister: Byte = 0x00

    public override var firstRegisterAddress: Address {
        return 0xff10
    }
    public override var controlFlag: SoundControl.ChannelFlags {
        return .channel1
    }

    public override func reset() {
        super.reset()
        lock.lock()
        defer { lock.unlock() }
        sweepRegister = 0
    }

    public override func writeSweepInfoOrWaveEnabled(byte: Byte) {
        sweepRegister = byte
    }

    public override func getSweepInfoOrWaveEnabled() -> Byte {
        sweepRegister
    }
}

// MARK: - Square Channel 2

public final class SquareChannel2: SquareChannel {
    public override var firstRegisterAddress: Address {
        return 0xff15
    }
    public override var controlFlag: SoundControl.ChannelFlags {
        return .channel2
    }
}

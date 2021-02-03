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

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        waveDuty = .fiftyPercent
        soundLength = 0
        isSoundLengthEnabled = false
        combinedFrequencyRegister = 0
        volumeEnvelopeRegister = 0
    }

    public func writeSweepInfo(byte: Byte) {
        // no-op
    }

    public func getSweepInfo() -> Byte {
        // no-op
        return 0
    }
}

public final class SquareChannel1: SquareChannel, SweepChannel {
    public var sweepRegister: Byte = 0x00

    public override var firstRegisterAddress: Address {
        return 0xff10
    }

    public override func reset() {
        super.reset()
        lock.lock()
        defer { lock.unlock() }
        sweepRegister = 0
    }
}

public final class SquareChannel2: SquareChannel {
    public override var firstRegisterAddress: Address {
        return 0xff15
    }
}

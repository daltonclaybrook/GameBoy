import Foundation

public final class Square1Channel: LockableChannel, SweepChannel, WaveDutyChannel, LengthChannel, VolumeEnvelopeChannel, FrequencyChannel {

    public let firstRegisterAddress: Address = 0xff10
    public weak var delegate: ChannelDelegate?

    public var waveDuty: WaveDuty = .fiftyPercent
    public var soundLength: UInt8 = 0
    public var isSoundLengthEnabled = false
    public var combinedFrequencyRegister: UInt16 = 0x00

    public var sweepRegister: Byte = 0x00
    public var volumeEnvelopeRegister: Byte = 0x00
    public let lock = NSRecursiveLock()

    public func reset() {
        lock.lock()
        defer { lock.unlock() }

        waveDuty = .fiftyPercent
        soundLength = 0
        isSoundLengthEnabled = false
        combinedFrequencyRegister = 0
        sweepRegister = 0
        volumeEnvelopeRegister = 0
    }
}

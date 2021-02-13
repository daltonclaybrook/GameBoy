import Foundation

public final class WaveChannel:
    LockableChannel,
    LengthChannel,
    FrequencyChannel
{
    public enum Volume: UInt8 {
        case muted
        case fullVolume
        case fiftyPercent
        case twentyFivePercent
    }

    public weak var delegate: ChannelDelegate?
    public let lock = NSRecursiveLock()
    public var soundLength: UInt8 = 0
    public private(set) var isWaveEnabled = false
    public var isSoundLengthEnabled: Bool = false
    public var combinedFrequencyRegister: UInt16 = 0
    public var volume: Volume = .muted

    public var firstRegisterAddress: Address {
        return 0xff1a
    }

    public var controlFlag: SoundControl.ChannelFlags {
        return .channel3
    }

    public func getLengthMask() -> UInt8 {
        return 0xff // full 8 bits
    }

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        soundLength = 0
        isSoundLengthEnabled = false
        combinedFrequencyRegister = 0
    }

    public func writeSweepInfoOrWaveEnabled(byte: Byte) {
        // bit 7
        isWaveEnabled = (byte >> 7) & 1 == 1
    }

    public func writeVolumeInfo(byte: Byte) {
        // bits 5 & 6
        volume = Volume(rawValue: byte >> 5 & 0x03)! // This cannot crash
    }

    public func getSweepInfoOrWaveEnabled() -> Byte {
        // bit 7
        isWaveEnabled ? 0x80 : 0x00
    }

    public func getVolumeInfo() -> Byte {
        // bits 5 & 6
        volume.rawValue << 5
    }
}

public extension WaveChannel.Volume {
    var percent: Float {
        switch self {
        case .muted:
            return 0.0
        case .fullVolume:
            return 1.0
        case .fiftyPercent:
            return 0.5
        case .twentyFivePercent:
            return 0.25
        }
    }
}

import Foundation

public protocol ChannelDelegate: AnyObject {
    func channelShouldRestart(_ channel: Channel)
    func channel(_ channel: Channel, loadedSoundLength soundLength: UInt8)
}

public protocol Channel: AnyObject, MemoryAddressable {
    var firstRegisterAddress: Address { get }
    var controlFlag: SoundControl.ChannelEnabled { get }
    var delegate: ChannelDelegate? { get set }

    func reset()

    // MARK: - Optional locking

    func lockIfNecessary()
    func unlockIfNecessary()

    // MARK: - Writes

    func writeSweepInfoOrWaveEnabled(byte: Byte)
    func writeWaveDutyAndLength(byte: Byte)
    func writeVolumeInfo(byte: Byte)
    func writeLowFrequencyOrNoiseInfo(byte: Byte)
    func writeTriggerLengthEnableAndHighFrequency(byte: Byte)

    // MARK: - Reads

    func getSweepInfoOrWaveEnabled() -> Byte
    func getWaveDutyAndLength() -> Byte
    func getVolumeInfo() -> Byte
    func getLowFrequencyOrNoiseInfo() -> Byte
    func getLengthEnable() -> Byte
}

public extension Channel {
    func write(byte: Byte, to address: Address) {
        lockIfNecessary()
        defer { unlockIfNecessary() }

        switch address {
        case firstRegisterAddress:
            writeSweepInfoOrWaveEnabled(byte: byte)
        case firstRegisterAddress + 1:
            writeWaveDutyAndLength(byte: byte)
        case firstRegisterAddress + 2:
            writeVolumeInfo(byte: byte)
        case firstRegisterAddress + 3:
            writeLowFrequencyOrNoiseInfo(byte: byte)
        case firstRegisterAddress + 4:
            writeTriggerLengthEnableAndHighFrequency(byte: byte)
        default:
            fatalError("Invalid address: \(address.hexString)")
        }
    }

    func read(address: Address) -> Byte {
        switch address {
        case firstRegisterAddress:
            return getSweepInfoOrWaveEnabled()
        case firstRegisterAddress + 1:
            return getWaveDutyAndLength()
        case firstRegisterAddress + 2:
            return getVolumeInfo()
        case firstRegisterAddress + 3:
            return getLowFrequencyOrNoiseInfo()
        case firstRegisterAddress + 4:
            return getLengthEnable()
        default:
            fatalError("Invalid address: \(address.hexString)")
        }
    }
}

// MARK: - LockableChannel

public protocol LockableChannel: Channel {
    var lock: NSRecursiveLock { get }
}

public extension LockableChannel {
    func lockIfNecessary() {
        lock.lock()
    }

    func unlockIfNecessary() {
        lock.unlock()
    }
}

// MARK: - SweepChannel

public protocol SweepChannel: Channel {
    var sweepRegister: Byte { get set }
}

public extension SweepChannel {
    /// The count of cycles @ 128 Hz to wait before performing each
    /// frequency recalculation.
    var sweepCycleModulus: UInt8 {
        // bits 4-6
        sweepRegister >> 4 & 0x07
    }

    /// Whether the sweep should increase in frequency, or decrease
    var sweepDirection: SweepVolumeDirection {
        // When bit 3 is set, the frequency is decreasing
        sweepRegister >> 3 & 0x01 == 0 ? .increasing : .decreasing
    }

    /// Number used in the sweep calculation. The shadow frequency is
    /// shifted right by this number, optionally negated, then summed
    /// with the shadow frequency to produce the next frequency.
    var sweepShiftNumber: UInt8 {
        // bits 0-2
        sweepRegister & 0x07
    }

    func writeSweepInfo(byte: Byte) {
        sweepRegister = byte
    }

    func getSweepInfo() -> Byte {
        sweepRegister
    }
}

// MARK: - WaveDutyChannel

public protocol WaveDutyChannel: Channel {
    var waveDuty: WaveDuty { get set }
}

// MARK: - LengthChannel

public protocol LengthChannel: Channel {
    var soundLength: UInt8 { get set }
    var isSoundLengthEnabled: Bool { get set }

    /// Used to set a limit on the number of bits in a length. e.g. The
    /// pulse channels use 6-bit length, but the wave channel uses 8-bit.
    func getLengthMask() -> UInt8
}

public extension LengthChannel {
    func writeWaveDutyAndLength(byte: Byte) {
        soundLength = byte & getLengthMask()
        delegate?.channel(self, loadedSoundLength: soundLength)
    }

    func getWaveDutyAndLength() -> Byte {
        // This value seems to be accessible from wave and noise channels
        return soundLength
    }

    func getLengthEnable() -> Byte {
        // Only bit 6 is able to be read. The others are write-only
        return isSoundLengthEnabled ? 0x40 : 0x00
    }
}

// MARK: - Combined Wave Duty and Length Channels

public extension WaveDutyChannel where Self: LengthChannel {
    func getLengthMask() -> UInt8 { 0x3f }

    func writeWaveDutyAndLength(byte: Byte) {
        // only lower 6 bits affect sound length
        soundLength = byte & getLengthMask()
        waveDuty = WaveDuty(rawValue: byte >> 6)! // Cannot crash or I'll eat my hat
        delegate?.channel(self, loadedSoundLength: soundLength)
    }

    func getWaveDutyAndLength() -> Byte {
        // Sound length is not returned because it is write-only in this case
        return waveDuty.rawValue << 6
    }
}

// MARK: - VolumeEnvelopeChannel

public protocol VolumeEnvelopeChannel: Channel {
    var volumeEnvelopeRegister: Byte { get set }
}

public extension VolumeEnvelopeChannel {
    /// The volume of the envelope when the sound is started. This value
    /// ranges from `0x00...0x0f`.
    var initialVolumeOfEnvelope: UInt8 {
        // bits 4-7
        volumeEnvelopeRegister >> 4
    }

    /// Whether the volume should increase in amplitude, or decrease
    var envelopeDirection: SweepVolumeDirection {
        // When bit 3 is set, volume is increasing. This is the opposite
        // behavior of the `sweepDirection`.
        volumeEnvelopeRegister >> 3 & 0x01 == 0 ? .decreasing : .increasing
    }

    /// The count of cycles @ 64 Hz to wait before performing a new volume
    /// calculation.
    var envelopeCycleModulus: UInt8 {
        // Bits 0-2
        volumeEnvelopeRegister & 0x07
    }

    func writeVolumeInfo(byte: Byte) {
        volumeEnvelopeRegister = byte
    }

    func getVolumeInfo() -> Byte {
        return volumeEnvelopeRegister
    }
}

// MARK: - FrequencyChannel

public protocol FrequencyChannel: Channel {
    /// This variable contains the combined values of the lower and higher frequency
    /// registers. The actual frequency sent to the audio subsystem is derived from
    /// this value.
    var combinedFrequencyRegister: UInt16 { get set }
}

public extension FrequencyChannel {
    /// The frequency used by the square channels
    var squareFrequency: Float {
        131_072.0 / (2_048.0 - Float(combinedFrequencyRegister))
    }

    /// The frequency used by the wave channel
    var waveFrequency: Float {
        65_536.0 / (2_048.0 - Float(combinedFrequencyRegister))
    }

    func writeLowFrequencyOrNoiseInfo(byte: Byte) {
        combinedFrequencyRegister = (combinedFrequencyRegister & 0xff00) | UInt16(byte)
    }

    func getLowFrequencyOrNoiseInfo() -> Byte {
        return 0 // This register is write-only
    }

    func update(frequency: UInt16) {
        lockIfNecessary()
        defer { unlockIfNecessary() }
        combinedFrequencyRegister = frequency
    }
}

public extension FrequencyChannel where Self: LengthChannel {
    func writeTriggerLengthEnableAndHighFrequency(byte: Byte) {
        combinedFrequencyRegister = (UInt16(byte & 0x07) << 8) | (combinedFrequencyRegister & 0x00ff)
        isSoundLengthEnabled = (byte >> 6) & 1 != 0
        if (byte >> 7) & 0x01 == 1 {
            delegate?.channelShouldRestart(self)
        }
    }
}

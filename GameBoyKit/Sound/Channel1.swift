import Foundation

public protocol Channel1Delegate: AnyObject {
    func channel1ShouldRestart(_ channel1: Channel1)
    func channel1(_ channel1: Channel1, loadedSoundLength soundLength: UInt8)
}

public final class Channel1: MemoryAddressable {
    public enum WaveDuty: UInt8 {
        case twelvePointFivePercent // 12.5%
        case twentyFivePercent // 25%
        case fiftyPercent // 50%, default
        case seventyFivePercent // 75%
    }

    public weak var delegate: Channel1Delegate?
    public private(set) var waveDuty: WaveDuty = .fiftyPercent
    public private(set) var soundLength: UInt8 = 0
    public private(set) var isSoundLengthEnabled = false
    /// This variable contains the combined values of `0xff13` and the
    /// relevant bits of `0xff14`. The actual frequency is derived from
    /// this value.
    public private(set) var combinedFrequencyRegister: UInt16 = 0x00

    private var sweepRegister: Byte = 0x00
    private var volumeEnvelopeRegister: Byte = 0x00
    private let lock = NSRecursiveLock()

    public func write(byte: Byte, to address: Address) {
        lock.lock()
        defer { lock.unlock() }

        switch address {
        case 0xff10: // Set sweep
            sweepRegister = byte
        case 0xff11: // Set sound length and wave duty
            // only lower 6 bits affect sound length
            soundLength = byte & 0x3f
            waveDuty = WaveDuty(rawValue: byte >> 6)! // Cannot crash or I'll eat my hat
            delegate?.channel1(self, loadedSoundLength: soundLength)
        case 0xff12: // Set volume envelope
            volumeEnvelopeRegister = byte
        case 0xff13: // Set lower 8 bits of frequency register
            combinedFrequencyRegister = (combinedFrequencyRegister & 0xff00) | UInt16(byte)
        case 0xff14: // Set upper 3 bits of frequency register, sound length enable, and restart
            combinedFrequencyRegister = (UInt16(byte & 0x07) << 8) | (combinedFrequencyRegister & 0x00ff)
            isSoundLengthEnabled = (byte >> 6) & 0x01 == 1
            if (byte >> 7) & 0x01 == 1 {
                delegate?.channel1ShouldRestart(self)
            }
        default:
            fatalError("Invalid address: \(address)")
        }
    }

    public func read(address: Address) -> Byte {
        switch address {
        case 0xff10:
            return sweepRegister
        case 0xff11:
            // Sound length is not returned because it is write-only
            return waveDuty.rawValue << 6
        case 0xff12:
            return volumeEnvelopeRegister
        case 0xff13:
            return 0x00 // This register is write-only
        case 0xff14:
            // Only bit 6 is able to be read. The others are write-only
            return isSoundLengthEnabled ? 0x40 : 0x00
        default:
            fatalError("Invalid address: \(address)")
        }
    }

    internal func update(frequency: UInt16) {
        lock.lock()
        defer { lock.unlock() }
        combinedFrequencyRegister = frequency
    }
}

public extension Channel1 {
    /// A type used to indicate if the sweep/volume is increasing or decreasing
    enum Direction {
        case increasing, decreasing
    }

    /// The frequency is derived by combining the registers `0xff13` and
    /// part of `0xff14`, then applying a formula.
    var frequency: Float {
        131_072.0 / (2_048.0 - Float(combinedFrequencyRegister))
    }

    /// The count of cycles @ 128 Hz to wait before performing each
    /// frequency recalculation.
    var sweepCycleModulus: UInt8 {
        // bits 4-6
        sweepRegister >> 4 & 0x07
    }

    /// Whether the sweep should increase in frequency, or decrease
    var sweepDirection: Direction {
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

    /// The volume of the envelope when the sound is started. This value
    /// ranges from `0x00...0x0f`.
    var initialVolumeOfEnvelope: UInt8 {
        // bits 4-7
        volumeEnvelopeRegister >> 4
    }

    /// Whether the volume should increase in amplitude, or decrease
    var envelopeDirection: Direction {
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
}

public extension Channel1.WaveDuty {
    var waveform: [Float] {
        switch self {
        case .twelvePointFivePercent:
            return [-1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, 1.0]
        case .twentyFivePercent:
            return [1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, 1.0]
        case .fiftyPercent:
            return [1.0, -1.0, -1.0, -1.0, -1.0, 1.0, 1.0, 1.0]
        case .seventyFivePercent:
            return [-1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, -1.0]
        }
    }
}

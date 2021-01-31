public protocol Channel1Delegate: AnyObject {
    func channel1ShouldRestart(_ channel1: Channel1)
}

public final class Channel1: MemoryAddressable {
    public enum WaveDuty: UInt8 {
        case twelvePointFivePercent // 12.5%
        case twentyFivePercent // 25%
        case fiftyPercent // 50%
        case seventyFivePercent // 75%
    }

    /// The frequency derived by combining the registers `0xff13` and
    /// part of `0xff14`, then applying a formula.
    public var frequency: Double {
        131_072.0 / (2_048.0 - Double(combinedFrequencyRegister))
    }

    public weak var delegate: Channel1Delegate?
    public private(set) var waveDuty: WaveDuty = .twelvePointFivePercent
    public private(set) var soundLength: UInt8 = 0
    public private(set) var isSoundLengthEnabled = false

    private var sweepRegister: Byte = 0x00
    private var volumeEnvelopeRegister: Byte = 0x00
    /// This variable contains the combined values of `0xff13` and the
    /// relevant bits of `0xff14`. The actual frequency is derived from
    /// this value.
    private var combinedFrequencyRegister: UInt16 = 0x00

    public func write(byte: Byte, to address: Address) {
        switch address {
        case 0xff10: // Set sweep
            sweepRegister = byte
        case 0xff11: // Set sound length and wave duty
            // only lower 6 bits affect sound length
            soundLength = byte & 0x3f
            waveDuty = WaveDuty(rawValue: byte >> 6)!
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
}

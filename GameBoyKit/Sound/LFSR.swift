/// Implementation of the Linear-feedback shift register used to generate pseudo-random
/// numbers for use by the noise channel
public final class LFSR {
    public enum WidthMode: UInt8 {
        case long // 15-bits
        case short // 7-bits
    }

    public var widthMode: WidthMode = .long
    private var register: UInt16 = 0

    /// Returns bit 0 of the shift register, inverted
    public var output: UInt8 {
        UInt8((~register) & 1)
    }

    public init() {
        reset()
    }

    public func reset() {
        // high bit is 0 since it's a 15-bit register
        register = 0x7fff
    }

    public func shift() {
        let mask: UInt16 = widthMode == .short ? 0x4040 : 0x4000
        let highBit = (register & 1) ^ ((register >> 1) & 1) == 1
        register >>= 1
        if highBit {
            register |= mask
        } else {
            register &= ~mask
        }
    }
}

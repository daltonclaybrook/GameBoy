/// Implementation of the Linear-feedback shift register used to generate pseudo-random
/// numbers for
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
        // XOR the first two bits
        let xorResult = (register & 1) ^ ((register >> 1) & 1)
        register >>= 1
        // Store the result in the high bit, which is bit 14 (15-bit register)
        register |= xorResult << 14
        if widthMode == .short {
            // also stored in bit 6 when width mode == 1
            register |= xorResult << 6
        }
    }
}

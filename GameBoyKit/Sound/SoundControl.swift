/// This type represents the three sound control registers in the Game Boy
public final class SoundControl: MemoryAddressable {
    public struct ChannelEnabled: OptionSet {
        public private(set) var rawValue: Byte

        public static let channel1 = ChannelEnabled(rawValue: 1 << 0)
        public static let channel2 = ChannelEnabled(rawValue: 1 << 1)
        public static let channel3 = ChannelEnabled(rawValue: 1 << 2)
        public static let channel4 = ChannelEnabled(rawValue: 1 << 3)

        public init(rawValue: Byte) {
            self.rawValue = rawValue
        }
    }

    /// This is the master flag to determine if all sound is enabled
    /// or disabled. On the Game Boy, setting this to false can save
    /// 16% or more on power consumption.
    public private(set) var isSoundEnabled = false
    /// The APU sets the flags the sound channels are triggered and resets
    /// them when the sound length expires for a channel.
    internal var enabledChannels: ChannelEnabled = []

    private var volumeByte: Byte = 0x00
    private var routingByte: Byte = 0x00

    public func write(byte: Byte, to address: Address) {
        switch address {
        case 0xff24: // Volume control for left/right + Vin
            volumeByte = byte
        case 0xff25: // Channel routing to terminals
            routingByte = byte
        case 0xff26: // Turn all sound on/off
            isSoundEnabled = (byte >> 7) & 1 == 1
        default:
            fatalError("Invalid address: \(address)")
        }
    }

    public func read(address: Address) -> Byte {
        switch address {
        case 0xff24: // Volume control for left/right + Vin
            return volumeByte
        case 0xff25: // Channel routing to terminals
            return routingByte
        case 0xff26: // Turn all sound on/off
            let isEnabledBit: Byte = isSoundEnabled ? 0x80 : 0x00
            return isEnabledBit | enabledChannels.rawValue
        default:
            fatalError("Invalid address: \(address)")
        }
    }
}

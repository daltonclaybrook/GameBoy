public struct StereoVolume {
    let leftVolume: Float
    let rightVolume: Float
}

public protocol SoundControlDelegate: AnyObject {
    func soundControlDidStopAllSound(_ control: SoundControl)
    func soundControl(_ control: SoundControl, didUpdate stereoVolume: StereoVolume)
    func soundControlDidUpdateChannelRouting(_ control: SoundControl)
}

/// This type represents the three sound control registers in the Game Boy
public final class SoundControl: MemoryAddressable {
    public struct ChannelFlags: OptionSet {
        public private(set) var rawValue: Byte

        public static let channel1 = ChannelFlags(rawValue: 1 << 0)
        public static let channel2 = ChannelFlags(rawValue: 1 << 1)
        public static let channel3 = ChannelFlags(rawValue: 1 << 2)
        public static let channel4 = ChannelFlags(rawValue: 1 << 3)

        public init(rawValue: Byte) {
            self.rawValue = rawValue
        }
    }

    weak var delegate: SoundControlDelegate?

    /// This is the master flag to determine if all sound is enabled
    /// or disabled. On the Game Boy, setting this to false can save
    /// 16% or more on power consumption.
    public private(set) var isSoundEnabled = false
    /// The APU sets the flags the sound channels are triggered and resets
    /// them when the sound length expires for a channel.
    internal var enabledChannels: ChannelFlags = []

    private var volumeRegister: Byte = 0x00
    private var routingRegister: Byte = 0x00

    public func write(byte: Byte, to address: Address) {
        switch address {
        case 0xff24: // Volume control for left/right + Vin
            volumeRegister = byte
            delegate?.soundControl(self, didUpdate: stereoVolume)
        case 0xff25: // Channel routing to terminals
            routingRegister = byte
            delegate?.soundControlDidUpdateChannelRouting(self)
        case 0xff26: // Turn all sound on/off
            isSoundEnabled = (byte >> 7) & 1 == 1
            if !isSoundEnabled {
                delegate?.soundControlDidStopAllSound(self)
            }
        default:
            fatalError("Invalid address: \(address)")
        }
    }

    public func read(address: Address) -> Byte {
        switch address {
        case 0xff24: // Volume control for left/right + Vin
            return volumeRegister
        case 0xff25: // Channel routing to terminals
            return routingRegister
        case 0xff26: // Turn all sound on/off
            let isEnabledBit: Byte = isSoundEnabled ? 0x80 : 0x00
            return isEnabledBit | enabledChannels.rawValue
        default:
            fatalError("Invalid address: \(address)")
        }
    }
}

public extension SoundControl {
    var stereoVolume: StereoVolume {
        let leftVolume = Float((volumeRegister >> 4) & 0x07)
        let rightVolume = Float(volumeRegister & 0x07)
        return StereoVolume(
            leftVolume: leftVolume / 7.0,
            rightVolume: rightVolume / 7.0
        )
    }

    func getStereoVolume(for channelFlag: ChannelFlags) -> StereoVolume {
        let leftOn = routingRegister & (channelFlag.rawValue << 4) != 0
        let rightOn = routingRegister & channelFlag.rawValue != 0
        return StereoVolume(
            leftVolume: leftOn ? 1.0 : 0.0,
            rightVolume: rightOn ? 1.0 : 0.0
        )
    }
}

extension StereoVolume {
    var masterVolume: Float {
        (leftVolume + rightVolume) / 2.0
    }

    var pan: Float {
        let minVolume = min(leftVolume, rightVolume)
        let maxVolume = max(leftVolume, rightVolume)
        let absolutePan = 1.0 - (minVolume / maxVolume)
        return leftVolume > rightVolume ? -absolutePan : absolutePan
    }
}

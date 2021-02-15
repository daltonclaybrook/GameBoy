public enum WaveDuty: UInt8 {
    case twelvePointFivePercent // 12.5%
    case twentyFivePercent // 25%
    case fiftyPercent // 50%, default
    case seventyFivePercent // 75%
}

public extension WaveDuty {
    var percent: Float {
        switch self {
        case .twelvePointFivePercent:
            return 0.125
        case .twentyFivePercent:
            return 0.25
        case .fiftyPercent:
            return 0.50
        case .seventyFivePercent:
            return 0.75
        }
    }
}

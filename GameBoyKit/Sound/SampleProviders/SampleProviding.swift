public let twoPi = 2 * Float.pi
/// This seems to be a sensible multiplier
public let amplitudeMultiplier: Float = 0.5

public protocol SampleProviding {
    func generateSample() -> StereoSample
    func soundControlDidUpdateRouting()
    func restart()
}

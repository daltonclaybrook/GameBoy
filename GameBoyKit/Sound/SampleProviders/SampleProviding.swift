public let twoPi = 2 * Float.pi

public protocol SampleProviding {
    func generateSample() -> StereoSample
    func soundControlDidUpdateRouting()
    func restart()
}

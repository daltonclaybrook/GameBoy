import QuartzCore

public final class DisplayLink: DisplayLinkType {
    private lazy var displayLink = CADisplayLink(
        target: self,
        selector: #selector(displayLinkDidFire)
    )
    private var renderCallback: ((FramesPerSecond) -> Void)?

    public init() {}

    public func start() {
        displayLink.add(to: .current, forMode: .default)
    }

    public func stop() {
        displayLink.invalidate()
    }

    public func setRenderCallback(_ callback: @escaping (FramesPerSecond) -> Void) {
        self.renderCallback = callback
    }

    // MARK: - Helpers

    @objc
    private func displayLinkDidFire() {
        let framesPerSecond = 1 / (displayLink.targetTimestamp - displayLink.timestamp)
        renderCallback?(framesPerSecond)
    }
}

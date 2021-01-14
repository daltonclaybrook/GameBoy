import CoreVideo

public typealias FramesPerSecond = Double

public protocol DisplayLinkType: AnyObject {
    func start()
    func stop()
    func setRenderCallback(_ callback: @escaping (_ rate: FramesPerSecond) -> Void)
}

public final class DisplayLink: DisplayLinkType {
    enum Error: Swift.Error {
        case errorCreatingDisplayLink
        case errorRegisteringDisplayLinkCallback
    }

    private let displayLink: CVDisplayLink
    private var notificationToken: NSObjectProtocol?
    private var renderCallback: ((_ rate: FramesPerSecond) -> Void)?

    public init() throws {
        var outLink: CVDisplayLink?
        var result = CVDisplayLinkCreateWithActiveCGDisplays(&outLink)
        guard let displayLink = outLink, result == kCVReturnSuccess else {
            assertionFailure("error creating display link: \(result)")
            throw Error.errorCreatingDisplayLink
        }

        self.displayLink = displayLink

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        result = CVDisplayLinkSetOutputCallback(displayLink, outputCallback, selfPtr)
        guard result == kCVReturnSuccess else {
            assertionFailure("failed to register display link callback")
            throw Error.errorRegisteringDisplayLinkCallback
        }

        notificationToken = NotificationCenter.default
            .addObserver(forName: NSWindow.willCloseNotification, object: nil, queue: nil) { [weak self] _ in
                self?.stop()
            }
    }

    deinit {
        if let token = notificationToken {
            NotificationCenter.default.removeObserver(token)
        }
        stop()
        CVDisplayLinkSetOutputCallback(displayLink, nil, nil)
    }

    public func start() {
        guard !CVDisplayLinkIsRunning(displayLink) else { return }
        let result = CVDisplayLinkStart(displayLink)
        assert(result == kCVReturnSuccess, "Unable to start display link")
    }

    public func stop() {
        guard CVDisplayLinkIsRunning(displayLink) else { return }
        CVDisplayLinkStop(displayLink)
    }

    public func setRenderCallback(_ callback: @escaping (_ rate: FramesPerSecond) -> Void) {
        self.renderCallback = callback
    }

    // MARK: - Helper instance functions

    fileprivate func displayLinkDidFire() {
        let period = CVDisplayLinkGetActualOutputVideoRefreshPeriod(displayLink)
        renderCallback?(1.0 / period) // Frames per second
    }
}

// MARK: - Free helper functions

private func outputCallback(displayLink: CVDisplayLink, inNow: UnsafePointer<CVTimeStamp>, inOutputTime: UnsafePointer<CVTimeStamp>, flagsIn: CVOptionFlags, flagsOut: UnsafeMutablePointer<CVOptionFlags>, context: UnsafeMutableRawPointer?) -> CVReturn {
    guard let context = context else { return kCVReturnError }
    let owner = Unmanaged<DisplayLink>.fromOpaque(context).takeUnretainedValue()
    owner.displayLinkDidFire()
    return kCVReturnSuccess
}

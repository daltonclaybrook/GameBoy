public typealias FramesPerSecond = Double

public protocol DisplayLinkType: AnyObject {
    func start()
    func stop()
    func setRenderCallback(_ callback: @escaping (_ fps: FramesPerSecond) -> Void)
}

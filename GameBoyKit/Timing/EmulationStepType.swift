/// The rate at which the emulation step function is called on types conforming
/// to `EmulationStepType`
public enum StepRate {
    /// Called at either normal or double speed depending on the system speed mode
    case matchSpeedMode
    /// Always called at normal speed, regardless of the system speed mode
    case alwaysNormalSpeed
}

/// Types that conform to this protocol are called when emulation advances and
/// an emulation step occurs. The type can specify whether it is affected by double
/// speed mode on the Game Boy Color. If so, it will be called twice as frequently
/// while double speed mode is active.
public protocol EmulationStepType {
    /// The rate at which the emulation step function is called
    var stepRate: StepRate { get }
    /// Called at each step of emulation. In normal speed mode, this is called once
    /// per m-cycle. In double speed mode, this may be called twice as fast, or
    /// it may be called at the same rate as normal speed mode depending on the
    /// value returned from `stepRate`
    func emulateStep()
}

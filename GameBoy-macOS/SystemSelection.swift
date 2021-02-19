import GameBoyKit

final class SystemSelection {
    static let shared = SystemSelection()
    private static let systemUserDefaultsKey = "systemUserDefaultsKey"

    private(set) var system: GameBoy.System

    private init() {
        let systemRawValue = UserDefaults.standard.integer(forKey: Self.systemUserDefaultsKey)
        self.system = GameBoy.System(rawValue: systemRawValue) ?? .dmg
    }

    func updateSystem(_ system: GameBoy.System) {
        self.system = system
        UserDefaults.standard.set(system.rawValue, forKey: Self.systemUserDefaultsKey)
    }
}

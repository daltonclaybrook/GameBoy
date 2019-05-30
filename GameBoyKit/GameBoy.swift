public final class GameBoy {
	private let queue: DispatchQueue = DispatchQueue(
		label: "com.daltonclaybrook.GameBoy.GameBoy",
		qos: .userInteractive
	)

	public init() {
	}
}

import Foundation

struct AppConfig {
	enum RuntimeMode {
		case normal
		case unitTesting
	}

	static var runtimeMode: RuntimeMode {
		if NSClassFromString("XCTest") != nil {
			return .unitTesting
		} else {
			return .normal
		}
	}
}

import Cocoa
import GameBoyKit_macOS
import MetalKit

class ViewController: NSViewController {
	private let mtkView = MTKView()
	private var gameBoy: GameBoy?

	override func viewDidLoad() {
		super.viewDidLoad()

		view.addSubview(mtkView)
		mtkView.frame = view.bounds
		mtkView.autoresizingMask = [.width, .height]

		guard let device = MTLCreateSystemDefaultDevice() else {
			return assertionFailure("Metal device could not be created")
		}
		mtkView.device = device

		do {
			let renderer = try MetalRenderer(view: mtkView, device: device)
			let gameBoy = GameBoy(renderer: renderer)
			gameBoy.loadROM(data: try makeROMData())
			self.gameBoy = gameBoy
		} catch let error {
			return assertionFailure("error creating renderer: \(error)")
		}
	}

	private func makeROMData() throws -> Data {
		let fileURL = Bundle.main.url(forResource: "tetris", withExtension: "gb")!
		return try Data(contentsOf: fileURL)
	}
}


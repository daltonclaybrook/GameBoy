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
		let testRoms = [
			"cpu_instrs", // fails
			"01-special",
			"02-interrupts",
			"03-op sp,hl",
			"04-op r,imm",
			"05-op rp",
			"06-ld r,r",
			"07-jr,jp,call,ret,rst",
			"08-misc instrs",
			"09-op r,r",
			"10-bit ops",
			"11-op a,(hl)",
			"instr_timing",
			"interrupt_time"
		]
		let fileURL = Bundle.main.url(forResource: testRoms[12], withExtension: "gb")!
		return try Data(contentsOf: fileURL)
	}
}


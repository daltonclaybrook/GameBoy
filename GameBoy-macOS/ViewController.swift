import Cocoa
import GameBoyKit
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
            gameBoy.load(cartridge: try makeCartridge())
			self.gameBoy = gameBoy
		} catch let error {
			return assertionFailure("error creating renderer: \(error)")
		}
	}

	private func makeCartridge() throws -> CartridgeType {
		let testRoms = [
            // blargg
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
			"interrupt_time",
            // mooneye
            "call_timing",
            "call_timing2"
		]
		let fileURL = Bundle.main.url(forResource: testRoms[0], withExtension: "gb")!
		let fileData = try Data(contentsOf: fileURL)
        let cartridge = CartridgeFactory.makeCartridge(romBytes: [Byte](fileData))
        return cartridge
	}
}


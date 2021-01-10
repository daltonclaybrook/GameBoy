import GameBoyKit
import MetalKit
import UIKit

class ViewController: UIViewController {
    @IBOutlet var mtkView: MTKView!
    private var gameBoy: GameBoy?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Don't try to initialize Metal if we're unit testing
        guard AppConfig.runtimeMode == .normal else { return }

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
        //		let fileURL = Bundle.main.url(forResource: "tetris", withExtension: "gb")!
        let fileURL = Bundle.main.url(forResource: "call_timing", withExtension: "gb")!
        return try Data(contentsOf: fileURL)
    }
}


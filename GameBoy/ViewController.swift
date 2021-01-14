import GameBoyKit
import MetalKit
import UIKit

class ViewController: UIViewController {
    @IBOutlet var mtkView: MTKView!
    private var gameBoy: GameBoy?
    private let displayLink = DisplayLink()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Don't try to initialize Metal if we're unit testing
        guard AppConfig.runtimeMode == .normal else { return }

        guard let device = MTLCreateSystemDefaultDevice() else {
            return assertionFailure("Metal device could not be created")
        }
        mtkView.device = device

        var countCalled = 0
        var currentFPS: Double = 0
        let lock = NSLock()

        displayLink.setRenderCallback { fps in
            lock.lock()
            countCalled += 1
            currentFPS = fps
            lock.unlock()
        }
        displayLink.start()

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            lock.lock()
            print("times called: \(countCalled), fps: \(currentFPS)")
            countCalled = 0
            lock.unlock()
        }

        do {
//            let renderer = try MetalRenderer(view: mtkView, device: device)
//            let gameBoy = GameBoy(renderer: renderer)
//            gameBoy.loadROM(data: try makeROMData())
//            self.gameBoy = gameBoy
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


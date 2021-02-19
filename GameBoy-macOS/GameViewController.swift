import Cocoa
import GameBoyKit
import MetalKit

class GameViewController: NSViewController {
    private let viewSize = CGSize(width: 400, height: 360)
    private let mtkView = MTKView()
    private let mtlDevice = MTLCreateSystemDefaultDevice()

    private lazy var gameBoy: GameBoy? = {
        guard let device = mtlDevice else {
            assertionFailure("Metal device could not be created")
            return nil
        }
        do {
            let renderer = try MetalRenderer(view: mtkView, device: device)
            let gameBoy = GameBoy(system: SystemSelection.shared.system, renderer: renderer)
            return gameBoy
        } catch let error {
            assertionFailure("error creating game boy: \(error)")
            return nil
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.frame.size = viewSize
        view.addSubview(mtkView)
        mtkView.constrainEdgesToSuperview()
        mtkView.device = mtlDevice
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        gameBoy?.start()
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        gameBoy?.stop()
    }

    func loadCartridge(_ cartridge: CartridgeType) {
        gameBoy?.load(cartridge: cartridge)
    }

    // MARK: - Private

    private func makeCartridge() throws -> CartridgeType {
        // Passing tests
//        let fileURL = Bundle.main.url(forResource: "cpu_instrs", withExtension: "gb")!
//        let fileURL = Bundle.main.url(forResource: "intr_timing", withExtension: "gb")!
//        let fileURL = Bundle.main.url(forResource: "tim00", withExtension: "gb")!
//        let fileURL = Bundle.main.url(forResource: "div_timing", withExtension: "gb")!
//        let fileURL = Bundle.main.url(forResource: "oam_dma_start", withExtension: "gb")!
//        let fileURL = Bundle.main.url(forResource: "oam_dma_restart", withExtension: "gb")!
//        let fileURL = Bundle.main.url(forResource: "oam_dma_timing", withExtension: "gb")!
//        let fileURL = Bundle.main.url(forResource: "call_timing2", withExtension: "gb")!
//        let fileURL = Bundle.main.url(forResource: "dmg-acid2", withExtension: "gb")!
//        let fileURL = Bundle.main.url(forResource: "tetris", withExtension: "gb")!
//        let fileURL = Bundle.main.url(forResource: "mario", withExtension: "gb")!
        let fileURL = Bundle.main.url(forResource: "pokemon-red", withExtension: "gb")!

        // Failing tests
//        let fileURL = Bundle.main.url(forResource: "call_timing", withExtension: "gb")!
//        let fileURL = Bundle.main.url(forResource: "pokemon-yellow", withExtension: "gbc")!

        let fileData = try Data(contentsOf: fileURL)
        let (cartridge, _) = try CartridgeFactory.makeCartridge(romBytes: [Byte](fileData), externalRAMBytes: nil)
        return cartridge
    }

    private func generateAndSaveOAMImage() {
        guard let image = gameBoy?.ppu.generateDebugOAMImage(scale: 10) else {
            fatalError("Game Boy was nil")
        }
        let timestamp = Int(Date().timeIntervalSince1970)
        let filePath = NSString(string: "~/Desktop/oam-\(timestamp).png").expandingTildeInPath
        let url = URL(fileURLWithPath: filePath)
        print("Saving image to: \(url.path)")
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypePNG, 1, nil) else {
            fatalError("Unable to create destination")
        }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            fatalError("Unable to finalize image destination")
        }
    }
}

extension GameViewController: GameWindowControllerDelegate {
    func windowController(_ controller: GameWindowController, keyCodePressed keyCode: UInt16) {
        if keyCode == 31 {
            // Save OAM to disk when the "O" button is pressed
            generateAndSaveOAMImage()
        }

        guard let key = Joypad.Key(keyCode: keyCode) else { return }
        gameBoy?.joypad.keyWasPressed(key)
    }

    func windowController(_ controller: GameWindowController, keyCodeReleased keyCode: UInt16) {
        guard let key = Joypad.Key(keyCode: keyCode) else { return }
        gameBoy?.joypad.keyWasReleased(key)
    }
}

extension Joypad.Key {
    init?(keyCode: UInt16) {
        switch keyCode {
        case 2:
            self = .right
        case 0:
            self = .left
        case 13:
            self = .up
        case 1:
            self = .down
        case 37:
            self = .a
        case 40:
            self = .b
        case 43:
            self = .select
        case 47:
            self = .start
        default:
            return nil
        }
    }
}

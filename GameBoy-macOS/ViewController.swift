import Cocoa
import GameBoyKit
import MetalKit

class ViewController: NSViewController {
    private let mtkView = MTKView()
    private var gameBoy: GameBoy?
    private let viewSize = CGSize(width: 400, height: 360)
    private let displayLink = try! DisplayLink()

    override func viewDidLoad() {
        super.viewDidLoad()

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // This is the "O" key (for OAM)
            guard event.keyCode == 31 else { return event }
            self?.generateAndSaveOAMImage()
            return nil
        }

        view.frame.size = viewSize
        view.addSubview(mtkView)
        mtkView.frame = view.bounds
        mtkView.autoresizingMask = [.width, .height]

        guard let device = MTLCreateSystemDefaultDevice() else {
            return assertionFailure("Metal device could not be created")
        }
        mtkView.device = device

        do {
            let renderer = try MetalRenderer(view: mtkView, device: device)
            let gameBoy = GameBoy(renderer: renderer, displayLink: try! DisplayLink())
            let cartridge = try makeCartridge()
            self.title = cartridge.title
            gameBoy.load(cartridge: cartridge)
            self.gameBoy = gameBoy
        } catch let error {
            return assertionFailure("error creating renderer: \(error)")
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.title = self.title ?? "Game Boy"
    }

    private func makeCartridge() throws -> CartridgeType {
        let testRoms = [
            // blargg
            "cpu_instrs",
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
            "call_timing2",
            // games
            "tetris"
        ]

        // Passing tests
//        let fileURL = Bundle.main.url(forResource: "cpu_instrs", withExtension: "gb")!
//        let fileURL = Bundle.main.url(forResource: "intr_timing", withExtension: "gb")!
//        let fileURL = Bundle.main.url(forResource: "tim00", withExtension: "gb")!
//        let fileURL = Bundle.main.url(forResource: "div_timing", withExtension: "gb")!
//        let fileURL = Bundle.main.url(forResource: "oam_dma_start", withExtension: "gb")!
//        let fileURL = Bundle.main.url(forResource: "oam_dma_restart", withExtension: "gb")!
//        let fileURL = Bundle.main.url(forResource: "oam_dma_timing", withExtension: "gb")!
//        let fileURL = Bundle.main.url(forResource: "call_timing2", withExtension: "gb")!

        // Failing tests
//        let fileURL = Bundle.main.url(forResource: "call_timing", withExtension: "gb")!
//        let fileURL = Bundle.main.url(forResource: "dmg-acid2", withExtension: "gb")!
//        let fileURL = Bundle.main.url(forResource: "tetris", withExtension: "gb")!
        let fileURL = Bundle.main.url(forResource: "mario", withExtension: "gb")!
//        let fileURL = Bundle.main.url(forResource: "pokemon-yellow", withExtension: "gbc")!


        let fileData = try Data(contentsOf: fileURL)
        let cartridge = CartridgeFactory.makeCartridge(romBytes: [Byte](fileData))
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


public final class OAM: MemoryAddressable {
    public weak var mmu: MMU?
    var isBeingReadByPPU = false
    private(set) var oamBytes = [Byte](repeating: 0, count: MemoryMap.OAM.count)

    /// Clients use this view to access sprites from OAM memory at a discrete point
    /// in time. Unlike the `OAM` class, `OAMView` is thread safe.
    public var currentView: OAMView {
        OAMView(oamBytes: oamBytes)
    }

    private let dmaTransferDuration: Cycles = 160

    private var cyclesSinceStartOfTransfer: Cycles = 0
    private var requestedSource: Byte?
    private var startingSource: Byte?
    private var startedSource: Byte?

    public func read(address: Address) -> Byte {
        read(address: address, privileged: false)
    }

    public func read(address: Address, privileged: Bool) -> Byte {
        let mmu = getMMU()
        guard privileged || (!isBeingReadByPPU && !mmu.isDMATransferActive) else {
            // OAM cannot be read while being read by PPU or if a DMA transfer is active
            return 0xff
        }

        return oamBytes.read(address: address, in: .OAM)
    }

    public func write(byte: Byte, to address: Address) {
        write(byte: byte, to: address, privileged: false)
    }

    public func write(byte: Byte, to address: Address, privileged: Bool) {
        let mmu = getMMU()
        guard privileged || (!isBeingReadByPPU && !mmu.isDMATransferActive) else {
            // OAM cannot be written to while being read by PPU or if a DMA transfer is active
            return
        }
        oamBytes.write(byte: byte, to: address, in: .OAM)
    }

    public func startDMATransfer(source: Byte) {
        requestedSource = source
    }

    public func emulate() {
        let mmu = getMMU()
        if let startedSource = startedSource {
            emulateTransferActive(mmu: mmu, source: startedSource)
        }
        if let startingSource = startingSource {
            startNewDMATransfer(mmu: mmu, source: startingSource)
        }
        if let requestedSource = requestedSource {
            startingSource = requestedSource
            self.requestedSource = nil
        }
    }

    public func loadSavedBytes(_ bytes: [Byte]) {
        self.oamBytes = bytes
    }

    // MARK: - Helpers

    private func getMMU(file: StaticString = #file, line: UInt = #line) -> MMU {
        guard let mmu = mmu else {
            fatalError("MMU must not be nil", file: file, line: line)
        }
        return mmu
    }

    private func emulateTransferActive(mmu: MMU, source: Byte) {
        cyclesSinceStartOfTransfer += 1
        if cyclesSinceStartOfTransfer >= dmaTransferDuration {
            performDMATransfer(mmu: mmu, source: source)
            mmu.isDMATransferActive = false
            startedSource = nil
        }
    }

    private func startNewDMATransfer(mmu: MMU, source: Byte) {
        startedSource = source
        self.startingSource = nil
        cyclesSinceStartOfTransfer = 0
        mmu.isDMATransferActive = true
    }

    private func performDMATransfer(mmu: MMU, source: Byte) {
        let sourceAddress = Address(source) * 0x100
        (0..<Address(MemoryMap.OAM.count)).forEach { offset in
            let from = sourceAddress + offset
            let byte = mmu.read(address: from, privileged: true)
            oamBytes.write(byte: byte, to: offset)
        }
    }
}

public struct OAMView {
    let oamBytes: [Byte]

    private let totalSpriteCount = 40
    private let spritesPerLine = 10

    /// This function is used by the PPU for Mode 2, i.e. searching OAM. It returns up to 10 sprites that
    /// are visible on the provided line.
    public func findSortedSpriteAttributes(forLine line: UInt8, objectSize: LCDControl.ObjectSize) -> [SpriteAttributes] {
        var sprites: [SpriteAttributes] = []
        for index in (0..<totalSpriteCount) {
            let sprite = getSprite(atIndex: index)
            let lineRange = sprite.getLineRangeRelativeToScreen(objectSize: objectSize)
            guard lineRange.contains(Int16(line)) else {
                continue
            }

            sprites.append(sprite)
            if sprites.count == spritesPerLine {
                break
            }
        }

        // This sorting is only done on non-color Game Boy. CGB uses the order in OAM.
        return sprites.sorted { left, right in
            left.position.x < right.position.x
        }
    }

    // MARK: - Internal Helpers

    func getSprite(atIndex: Int) -> SpriteAttributes {
        let byteOffset = atIndex * 4
        let range = byteOffset..<(byteOffset + 4)
        let bytes = oamBytes[range]
        return SpriteAttributes(rawValue: bytes)
    }
}

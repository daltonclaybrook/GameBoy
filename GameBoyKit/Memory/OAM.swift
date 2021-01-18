public final class OAM: MemoryAddressable {
    public weak var mmu: MMU?
    private var oamBytes = [Byte](repeating: 0, count: MemoryMap.OAM.count)

    private let dmaTransferDuration: Cycles = 160

    private var cyclesSinceStartOfTransfer: Cycles = 0
    private var requestedSource: Byte?
    private var startingSource: Byte?
    private var startedSource: Byte?

    public func read(address: Address) -> Byte {
        if let mmu = mmu, mmu.isDMATransferActive {
            // OAM cannot be read while a DMA transfer is active
            return 0xff
        }
        return oamBytes.read(address: address, in: .OAM)
    }

    public func write(byte: Byte, to address: Address) {
        oamBytes.write(byte: byte, to: address, in: .OAM)
    }

    public func startDMATransfer(source: Byte) {
        requestedSource = source
    }

    public func emulate() {
        guard let mmu = mmu else { return }

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

    // MARK: - Helpers

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

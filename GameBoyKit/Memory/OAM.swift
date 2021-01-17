public final class OAM: MemoryAddressable {
    public weak var mmu: MMU?
    private var oamBytes = [Byte](repeating: 0, count: MemoryMap.OAM.count)

    private let dmaTransferDuration: Cycles = 160
    private let dmaTransferStartDelay: Cycles = 2

    private var queuedDMATransfer = false
    private var cyclesSinceStartOfTransfer: Cycles = 0
    private var cyclesUntilTransferStarts: Cycles = 0
    private var transferSource: Byte = 0

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
        transferSource = source
        cyclesSinceStartOfTransfer = 0
        cyclesUntilTransferStarts = dmaTransferStartDelay
        queuedDMATransfer = true
    }

    public func emulate() {
        guard let mmu = mmu else { return }
        if queuedDMATransfer {
            emulateQueuedTransfer(mmu: mmu)
        } else if mmu.isDMATransferActive {
            emulateTransferActive(mmu: mmu)
        }
    }

    // MARK: - Helpers

    private func emulateQueuedTransfer(mmu: MMU) {
        cyclesUntilTransferStarts -= 1
        if cyclesUntilTransferStarts == 0 {
            queuedDMATransfer = false
            mmu.isDMATransferActive = true
        }
    }

    private func emulateTransferActive(mmu: MMU) {
        cyclesSinceStartOfTransfer += 1
        if cyclesSinceStartOfTransfer >= dmaTransferDuration {
            performDMATransfer(mmu: mmu)
            mmu.isDMATransferActive = false
        }
    }

    private func performDMATransfer(mmu: MMU) {
        let sourceAddress = Address(transferSource) * 0x100
        (0..<Address(MemoryMap.OAM.count)).forEach { offset in
            let from = sourceAddress + offset
            let byte = mmu.read(address: from, privileged: true)
            oamBytes.write(byte: byte, to: offset)
        }
    }
}

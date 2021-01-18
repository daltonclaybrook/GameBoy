private struct QueuedDMATransfer {
    let source: Byte
    var cyclesUntilTransferStarts: Cycles
}

public final class OAM: MemoryAddressable {
    public weak var mmu: MMU?
    private var oamBytes = [Byte](repeating: 0, count: MemoryMap.OAM.count)

    private let dmaTransferDuration: Cycles = 160
    private let dmaTransferStartDelay: Cycles = 2

    /// A FIFO stack of requested DMA transfers. Because of the delay between
    /// when a transfer is requested and when it begins, it is possible for
    /// several transfers to get queued up one after another.
    private var queuedTransfers: [QueuedDMATransfer] = []
    private var cyclesSinceStartOfTransfer: Cycles = 0
    private var currentTransferSource: Byte = 0

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
        queuedTransfers.append(
            QueuedDMATransfer(
                source: source,
                cyclesUntilTransferStarts: getStartDelayForQueuedDMATransfer()
            )
        )
    }

    public func emulate() {
        guard let mmu = mmu else { return }
        emulateQueuedTransfers(mmu: mmu)
        // begin immediately if transfer is activated in the step above
        emulateActiveTransferIfNecessary(mmu: mmu)
    }

    // MARK: - Helpers

    private func getStartDelayForQueuedDMATransfer() -> Cycles {
        if mmu?.isDMATransferActive ?? false {
            // This might be a hack. The mooneye oam_dma_restart test seems to fail
            // if the start delay is the same for a fresh start and a restart.
            return dmaTransferStartDelay + 1
        } else {
            return dmaTransferStartDelay
        }
    }

    private func emulateQueuedTransfers(mmu: MMU) {
        var index = 0
        while index < queuedTransfers.count {
            defer { index += 1 }
            queuedTransfers[index].cyclesUntilTransferStarts -= 1

            if queuedTransfers[index].cyclesUntilTransferStarts == 0 {
                let transfer = queuedTransfers.remove(at: index)
                index -= 1
                currentTransferSource = transfer.source
                cyclesSinceStartOfTransfer = 0
                mmu.isDMATransferActive = true
            }
        }
    }

    private func emulateActiveTransferIfNecessary(mmu: MMU) {
        guard mmu.isDMATransferActive else { return }

        cyclesSinceStartOfTransfer += 1
        if cyclesSinceStartOfTransfer >= dmaTransferDuration {
            performDMATransfer(mmu: mmu)
            mmu.isDMATransferActive = false
        }
    }

    private func performDMATransfer(mmu: MMU) {
        let sourceAddress = Address(currentTransferSource) * 0x100
        (0..<Address(MemoryMap.OAM.count)).forEach { offset in
            let from = sourceAddress + offset
            let byte = mmu.read(address: from, privileged: true)
            oamBytes.write(byte: byte, to: offset)
        }
    }
}

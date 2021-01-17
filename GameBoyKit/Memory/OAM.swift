public final class OAM: MemoryAddressable {
    public weak var mmu: MMU?
    private var oamBytes = [Byte](repeating: 0, count: MemoryMap.OAM.count)
    private var cyclesSinceStartOfTransfer: Cycles = 0
    private let dmaTransferDuration: Cycles = 160
    private var transferSource: Byte = 0

    public func read(address: Address) -> Byte {
        return oamBytes.read(address: address, in: .OAM)
    }

    public func write(byte: Byte, to address: Address) {
        oamBytes.write(byte: byte, to: address, in: .OAM)
    }

    public func startDMATransfer(source: Byte) {
        guard let mmu = mmu else {
            fatalError("DMA transfer cannot start because no MMU is assigned")
        }
        transferSource = source
        cyclesSinceStartOfTransfer = 0
        mmu.isDMATransferActive = true
    }

    public func emulate() {
        guard let mmu = mmu, mmu.isDMATransferActive else { return }
        cyclesSinceStartOfTransfer += 1
        if cyclesSinceStartOfTransfer >= dmaTransferDuration {
            performDMATransfer(mmu: mmu)
            mmu.isDMATransferActive = false
        }
    }

    // MARK: - Helpers

    private func performDMATransfer(mmu: MMU) {
        let sourceAddress = Address(transferSource) * 0x100
        (0..<Address(MemoryMap.OAM.count)).forEach { offset in
            let from = sourceAddress + offset
            let byte = mmu.read(address: from, privileged: true)
            oamBytes.write(byte: byte, to: offset)
        }
    }
}

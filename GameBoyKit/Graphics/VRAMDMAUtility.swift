/// Utility used to initiate VRAM DMA transfers on the Game Boy Color
public final class VRAMDMAUtility: MemoryAddressable {
    private struct Registers {
        static let sourceHigh: Address = 0xff51
        static let sourceLow: Address = 0xff52
        static let destinationHigh: Address = 0xff53
        static let destinationLow: Address = 0xff54
        static let lengthModeStart: Address = 0xff55
    }

    /// The specified mode of the DMA transfer
    private enum TransferMode: UInt8 {
        /// The transfer occurs all at once and program execution is stopped while it occurs
        case generalPurpose
        /// The transfer occurs `0x10` bytes at a time, and each block is transferred at the
        /// start of H-blank. This transfer can be stopped while it is in progress.
        case hBlank
    }

    /// A weak reference to the memory unit used during the transfer
    weak var memory: (MemoryAddressable & AnyObject)?

    private var sourceRegister: UInt16 = 0
    private var destinationRegister: UInt16 = 0
    /// Only H-blank transfers cause this to be changed to `true` because general purpose transfers
    /// run synchronously.
    private var isHBlankTransferActive = false
    private var bytesAlreadyTransferred: UInt16 = 0
    private var bytesRemainingToBeTransferred: UInt16 = 0

    public func write(byte: Byte, to address: Address) {
        switch address {
        case Registers.sourceHigh:
            sourceRegister = (sourceRegister & 0x00ff) | (UInt16(byte) << 8)
        case Registers.sourceLow:
            sourceRegister = (sourceRegister & 0xff00) | UInt16(byte)
        case Registers.destinationHigh:
            destinationRegister = (destinationRegister & 0x00ff) | (UInt16(byte) << 8)
        case Registers.destinationLow:
            destinationRegister = (destinationRegister & 0xff00) | UInt16(byte)
        case Registers.lengthModeStart:
            let mode = TransferMode(rawValue: (byte >> 7) & 0x01)!
            if isHBlankTransferActive && mode == .generalPurpose {
                // Stop the transfer
                isHBlankTransferActive = false
            } else {
                let lengthBits = byte & 0x7f
                let transferLength = UInt16(lengthBits + 1) * 0x10
                startTransfer(mode: mode, length: transferLength)
            }
        default:
            fatalError("Invalid address: \(address.hexString)")
        }
    }

    public func read(address: Address) -> Byte {
        switch address {
        case Registers.sourceHigh:
            return Byte(sourceRegister >> 8)
        case Registers.sourceLow:
            return Byte(sourceRegister & 0xff)
        case Registers.destinationHigh:
            return Byte(destinationRegister >> 8)
        case Registers.destinationLow:
            return Byte(destinationRegister & 0xff)
        case Registers.lengthModeStart:
            // 7th bit 0 is active, 1 inactive
            let isActiveBit: Byte = isHBlankTransferActive ? 0x00 : 0x80
            let blocksRemaining = bytesRemainingToBeTransferred == 0 ? 0x7f : Byte(bytesRemainingToBeTransferred / 0x10 - 1)
            // If a transfer has finished, this should return `0xff`
            return isActiveBit | blocksRemaining
        default:
            fatalError("Invalid address: \(address.hexString)")
        }
    }

    /// Called by the PPU when transitioning from LCD transfer mode to H-blank mode
    public func didTransitionToHBlankMode() {
        guard isHBlankTransferActive else { return }
        // Transfer `0x10` bytes each H-blank
        transferNextBytes(count: 0x10)
    }

    // MARK: - Helpers

    private func startTransfer(mode: TransferMode, length: UInt16) {
        bytesAlreadyTransferred = 0
        bytesRemainingToBeTransferred = length

        switch mode {
        case .generalPurpose:
            transferNextBytes(count: length)
        case .hBlank:
            isHBlankTransferActive = true
        }
    }

    private func transferNextBytes(count: UInt16) {
        guard let memory = memory else {
            fatalError("Memory must be set before transfer occurs")
        }

        // Lower four bits of source register are ignored
        let adjustedSource = sourceRegister & 0xfff0
        // Only bits 4-12 are used, the rest are ignored, and a base address of 0x8000 is added
        let adjustedDestination = (destinationRegister & 0x1ff0) + MemoryMap.VRAM.lowerBound

        // Transfer up to `count` bytes
        for _ in 0..<count {
            let nextDestination = adjustedDestination + bytesAlreadyTransferred
            guard MemoryMap.VRAM.contains(nextDestination) && bytesRemainingToBeTransferred > 0 else {
                // end transfer prematurely if the next destination is outside of VRAM
                isHBlankTransferActive = false
                return
            }

            let nextSource = adjustedSource + bytesAlreadyTransferred
            let byteToTransfer = memory.read(address: nextSource)
            memory.write(byte: byteToTransfer, to: nextDestination)
            bytesAlreadyTransferred += 1
            bytesRemainingToBeTransferred -= 1
        }
    }
}

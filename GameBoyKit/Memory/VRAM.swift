public final class VRAM: MemoryAddressable {
    private(set) var bytes = [Byte](repeating: 0, count: MemoryMap.VRAM.count)
    /// The VRAM becomes locked when the PPU is drawing to the screen.
    /// At this time, reads/writes do not work and reads return a
    /// default value.
    var isBeingReadByPPU: Bool = false

    public func read(address: Address) -> Byte {
        read(address: address, privileged: false)
    }

    public func write(byte: Byte, to address: Address) {
        guard !isBeingReadByPPU else { return }
        bytes.write(byte: byte, to: address, in: .VRAM)
    }

    /// Privileged reads can be performed by the PPU when drawing to
    /// the screen. This will cause the `isLocked` setting to be
    /// ignored.
    public func read(address: Address, privileged: Bool) -> Byte {
        guard !isBeingReadByPPU || privileged else { return 0xff } // is this the right default?
        return bytes.read(address: address, in: .VRAM)
    }

    public func readWord(address: Address, privileged: Bool) -> Word {
        let little = read(address: address, privileged: privileged)
        let big = read(address: address + 1, privileged: privileged)
        return (UInt16(big) << 8) | UInt16(little)
    }

    public func loadSavedBytes(_ bytes: [Byte]) {
        self.bytes = bytes
    }
}

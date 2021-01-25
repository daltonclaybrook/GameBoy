public struct SaveData {
    public let vramBytes: [Byte]
    public let externalRAMBytes: [Byte]?
    public let wramBytes: [Byte]
    public let oamBytes: [Byte]
    public let hramBytes: [Byte]
}

public extension SaveData {
    enum Error: Swift.Error {
        case incorrectSize
    }

    init(bytes: [Byte], ramSize: RAMSize) throws {
        // Todo: Will have to rethink this with CGB since WRAM is bank-switchable
        let totalSize = MemoryMap.VRAM.count +
            Int(ramSize.size) +
            MemoryMap.WRAM.count +
            MemoryMap.OAM.count +
            MemoryMap.HRAM.count
        guard bytes.count == totalSize else {
            throw Error.incorrectSize
        }
        var bytes = bytes
        self.vramBytes = Array(bytes.removeAndReturnFirst(MemoryMap.VRAM.count))
        self.externalRAMBytes = ramSize.size > 0 ? Array(bytes.removeAndReturnFirst(Int(ramSize.size))) : nil
        self.wramBytes = Array(bytes.removeAndReturnFirst(MemoryMap.WRAM.count))
        self.oamBytes = Array(bytes.removeAndReturnFirst(MemoryMap.OAM.count))
        self.hramBytes = bytes
    }

    var allBytes: [Byte] {
        let externalRAM = externalRAMBytes ?? []
        return vramBytes +
            externalRAM +
            wramBytes +
            oamBytes +
            hramBytes
    }
}

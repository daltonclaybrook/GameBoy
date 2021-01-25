public protocol CartridgeType: MemoryAddressable {
    var externalRAMBytes: [Byte] { get }
    func loadExternalRAM(bytes: [Byte])
}

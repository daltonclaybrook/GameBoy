public protocol CartridgeDelegate: AnyObject {
    func cartridge(_ cartridge: CartridgeType, didSaveExternalRAM bytes: [Byte])
}

public protocol CartridgeType: AnyObject, MemoryAddressable {
    // Todo: consider making ram and delegate part of another protocol like
    // `RAMCatridgeType`
    var ramBytes: [Byte] { get }
    var delegate: CartridgeDelegate? { set get }
}

public protocol MemoryMasking: MemoryAddressable {
    func isAddressMasked(_ address: Address) -> Bool
}

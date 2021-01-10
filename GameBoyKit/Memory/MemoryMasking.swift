public protocol MemoryMasking: MemoryAddressable {
    var maskRange: ClosedRange<Address> { get }
}

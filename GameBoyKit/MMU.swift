public final class MMU: MemoryAddressable {
	public let addressableRange: ClosedRange<Address> = (0...0xffff)

	private var devices: [MemoryAddressable] = []

	public func read(address: Address) -> Byte {
		guard let device = devices.first(where: { $0.addressableRange.contains(address) }) else {
			fatalError("No device for the address: \(address)")
		}
		return device.read(address: address)
	}

	public func write(byte: Byte, to address: Address) {
		guard let device = devices.first(where: { $0.addressableRange.contains(address) }) else {
			fatalError("No device for the address: \(address)")
		}
		device.write(byte: byte, to: address)
	}

	public func register(device: MemoryAddressable) {
		devices.append(device)
	}
}

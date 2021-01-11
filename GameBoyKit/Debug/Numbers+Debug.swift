public extension Byte {
    var hexString: String {
        String(format: "%02X", self)
    }
}

public extension Address {
    var hexString: String {
        String(format: "%02x", self)
    }
}

public extension Byte {
    var hexString: String {
        String(format: "%02X", self)
    }

    var binaryString: String {
        String(self, radix: 2)
    }
}

public extension Address {
    var hexString: String {
        String(format: "%02x", self)
    }

    var binaryString: String {
        String(self, radix: 2)
    }
}

public extension UInt32 {
    var hexString: String {
        String(format: "%02x", self)
    }

    var binaryString: String {
        String(self, radix: 2)
    }
}

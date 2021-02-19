public extension Array {
    mutating func removeAndReturnFirst(_ count: Int) -> [Element] {
        defer { removeFirst(count) }
        return Array(self[0..<count])
    }
}

public extension Array where Element == Byte {
    subscript(addressRange: ClosedRange<Address>) -> ArraySlice<Byte> {
        self[Int(addressRange.lowerBound)...Int(addressRange.upperBound)]
    }
}

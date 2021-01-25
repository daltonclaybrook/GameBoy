public extension Array {
    mutating func removeAndReturnFirst(_ count: Int) -> [Element] {
        defer { removeFirst(count) }
        return Array(self[0..<count])
    }
}

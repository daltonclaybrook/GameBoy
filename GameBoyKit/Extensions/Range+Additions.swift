extension Range where Bound: AdditiveArithmetic {
    /// Create a new range by shifting the receiver by the given offset
    func shifted(by offset: Bound) -> Self {
        (lowerBound + offset)..<(upperBound + offset)
    }
}

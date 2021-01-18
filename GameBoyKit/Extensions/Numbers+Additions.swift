extension FixedWidthInteger {
    mutating func incrementReportingOverflow() -> Bool {
        let (newValue, didOverflow) = addingReportingOverflow(1)
        self = newValue
        return didOverflow
    }
}

extension Word {
    /// Add a signed 8-bit integer to an unsigned 16-bit integer.
    /// If the signed int is negative, the effect will be to subtract
    /// its absolute value from the unsigned int.
    static func &+ (lhs: Word, rhs: Int8) -> Word {
        if rhs >= 0 {
            return lhs &+ Word(rhs)
        } else {
            return lhs &- Word(abs(rhs))
        }
    }
}

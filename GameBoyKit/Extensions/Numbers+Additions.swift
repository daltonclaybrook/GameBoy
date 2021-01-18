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
    func signedAdd(value: Int8) -> Word {
        if value >= 0 {
            return self &+ Word(value)
        } else {
            // Because the range of `Int8` is -128 to 127, `abs(-128)` will
            // result in an arithmetic overflow and crash. So we need to
            // convert it to 16-bit before taking the `abs`.
            return self &- Word(truncatingIfNeeded: abs(Int16(value)))
        }
    }

    func signedAdd(value: Int16) -> Word {
        if value >= 0 {
            return self &+ Word(value)
        } else {
            // See note about about this odd-looking conversion
            return self &- Word(truncatingIfNeeded: abs(Int32(value)))
        }
    }
}

extension FixedWidthInteger {
    mutating func incrementReportingOverflow() -> Bool {
        let (newValue, didOverflow) = addingReportingOverflow(1)
        self = newValue
        return didOverflow
    }
}

extension Word {
    func wrappingAdd(_ value: Int8) -> Word {
        if value >= 0 {
            return self &+ Word(value)
        } else {
            return self &- Word(abs(value))
        }
    }
}

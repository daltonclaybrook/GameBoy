extension FixedWidthInteger {
    mutating func incrementReportingOverflow() -> Bool {
        let (newValue, didOverflow) = addingReportingOverflow(1)
        self = newValue
        return didOverflow
    }
}

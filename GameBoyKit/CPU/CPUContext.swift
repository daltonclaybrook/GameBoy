/// The context available to a CPU in order to perform reads/writes
/// and advance the clock
public protocol CPUContext {
    /// Perform an 8-bit read of the provided address and advance
    /// the system clock by one M-cycle
    func readCycle(address: Address) -> Byte
    /// Perform an 8-bit write to the provided address and advance
    /// the system clock by one M-cycle
    func writeCycle(byte: Byte, to address: Address)
    /// Advance the system clock by one M-cycle
    func tickCycle()
    /// Stop CPU execution, possibly to change speeds on CGB
    func stopAndChangeSpeedIfNecessary()
}

extension CPUContext {
    func readWordCycle(address: Address) -> Word {
        let low = readCycle(address: address)
        let high = readCycle(address: address &+ 1)
        return (Word(high) << 8) | Word(low)
    }

    func writeCycle(word: Word, to address: Address) {
        let low = Byte(word & 0xff)
        let high = Byte(word >> 8)
        writeCycle(byte: low, to: address)
        writeCycle(byte: high, to: address &+ 1)
    }
}

public struct Opcode {
    public let mnemonic: String
    public let block: (CPU, CPUContext) -> Cycles
}

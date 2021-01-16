public struct Opcode {
    public let mnemonic: String
    public let executeBlock: (CPU, CPUContext) -> Void
}

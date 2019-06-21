struct Opcode {
	let mnemonic: String
	let block: (CPU) -> Cycles
}

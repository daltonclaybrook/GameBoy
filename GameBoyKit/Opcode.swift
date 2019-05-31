struct Opcode {
	let mnemonic: String
	let cycles: Cycles
	let block: (CPU) -> Void
}

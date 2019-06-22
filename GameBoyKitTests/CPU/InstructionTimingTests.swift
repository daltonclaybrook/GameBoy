import XCTest
@testable import GameBoyKit

final class InstructionTimingTests: XCTestCase {
	func testMainTimingsWithFalseConditionals() {
		testTimings(
			opcodes: CPU.allOpcodes,
			setupBlocks: makeConditionalSetupBlocks(condition: false),
			timings: InstructionTimingTests.mainTimings
		)
	}

	func testMainTimingsWithTrueConditionals() {
		testTimings(
			opcodes: CPU.allOpcodes,
			setupBlocks: makeConditionalSetupBlocks(condition: true),
			timings: InstructionTimingTests.conditionalTimings
		)
	}

	func testCBTimings() {
		testTimings(
			opcodes: CPU.cbOpcodes,
			setupBlocks: makeNopSetupBlocks(),
			timings: InstructionTimingTests.cbPrefixedTimings
		)
	}

	// MARK: - Private

	private func testTimings(opcodes: [Opcode], setupBlocks: [(CPU) -> Void], timings: [Cycles], file: StaticString = #file, line: UInt = #line) {
		let mmu = MockMMU()
		for opcodeIndex in (0...Int(Byte.max)) {
			let expectedTiming = timings[opcodeIndex]
			guard expectedTiming != 0 else { continue }
			let subject = CPU(mmu: mmu)
			setupBlocks[opcodeIndex](subject)
			let opcode = opcodes[opcodeIndex]
			let cycles = opcode.block(subject)

			let hex = String(format: "%02X", opcodeIndex)
			XCTAssertEqual(cycles, expectedTiming, "Opcode: 0x\(hex), expected time: \(expectedTiming), actual: \(cycles)", file: file, line: line)
		}
	}

	/// Generate an array of blocks which maps 1-to-1 with all main opcodes and, upon execution of
	/// a block, sets up the particular opcode to evaluate true or false based on the provided `condition`.
	///
	/// - Parameter condition: Whether all conditional opcodes should evaluate to true or false
	/// - Returns: An array of blocks to execute before testing an opcode
	private func makeConditionalSetupBlocks(condition: Bool) -> [(CPU) -> Void] {
		var blocks = makeNopSetupBlocks()
		InstructionTimingTests.flagConditionals.forEach { conditional in
			blocks[Int(conditional.opcode)] = { cpu in
				switch (conditional.expectTrue, condition) {
				case (true, true), (false, false):
					cpu.flags = conditional.flag
				case (true, false), (false, true):
					cpu.flags = []
				}
			}
		}
		return blocks
	}

	private func makeNopSetupBlocks() -> [(CPU) -> Void] {
		return (0...UInt8.max).map { _ in { _ in /* nop */ } }
	}
}

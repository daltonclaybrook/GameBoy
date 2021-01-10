@testable import GameBoyKit

struct CPURegisters {
    let a: UInt8
    let b: UInt8
    let c: UInt8
    let d: UInt8
    let e: UInt8
    let h: UInt8
    let l: UInt8
    let sp: UInt16
    let pc: UInt16
    let flags: Flags
}

struct InstructionTestExpectation {
    let inputRegister: CPURegisters
    let expectedRegisters: CPURegisters

    let memoryRead: [Address: Byte]
    let memoryWritten: [Address: Byte]
}

extension CPU {

}

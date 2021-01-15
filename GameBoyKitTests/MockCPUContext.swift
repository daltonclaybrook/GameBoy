import GameBoyKit

final class MockCPUContext: CPUContext {
    private(set) var readCount: Cycles = 0
    private(set) var writeCount: Cycles = 0
    private(set) var tickCount: Cycles = 0

    var totalCycleCount: Cycles {
        readCount + writeCount + tickCount
    }

    func readCycle(address: Address) -> Byte {
        readCount += 1
        return 0
    }

    func writeCycle(byte: Byte, to address: Address) {
        writeCount += 1
    }

    func tickCycle() {
        tickCount += 1
    }
}

public final class WavePattern: MemoryAddressable {
    public private(set) var samples: [Byte]

    private let samplesCount = 32
    private let lowerMemoryBound: Address = 0xff30
    var shouldPrint = false

    public init() {
        samples = [Byte](repeating: 0, count: samplesCount)
    }

    public func write(byte: Byte, to address: Address) {
        if shouldPrint {
            print("writing wave pattern byte: \(byte), address: \(address.hexString)")
        }

        let firstSampleIndex = (address - lowerMemoryBound) * 2
        samples.write(byte: byte >> 4, to: firstSampleIndex)
        samples.write(byte: byte & 0x0f, to: firstSampleIndex + 1)
    }

    public func read(address: Address) -> Byte {
        let firstSampleIndex = (address - lowerMemoryBound) * 2
        let firstSample = samples.read(address: firstSampleIndex) << 4
        let secondSample = samples.read(address: firstSampleIndex + 1) & 0x0f
        return firstSample | secondSample
    }

    public func getSample(atNormalizedPhase phase: Float) -> UInt8 {
        let index = Int(phase * Float(samplesCount)) % samplesCount
        return samples[index]
    }
}

public final class WavePattern: MemoryAddressable {
    public private(set) var samples: [Byte]

    private let samplesCount = 32
    private let lowerMemoryBound: Address = 0xff30

    public init() {
        samples = [Byte](repeating: 0, count: samplesCount)
    }

    public func write(byte: Byte, to address: Address) {
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

    public func getSample(atNormalizedPhase phase: Float64) -> Float64 {
        let index = Int(phase * Float64(samplesCount)) % samplesCount
        return Float64(samples[index])
    }
}

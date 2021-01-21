import CoreGraphics
import Foundation
#if os(iOS)
import MobileCoreServices
#endif

extension VRAM {
    func writeDebugImagesAndDataToDisk(io: IO) {
        guard let tileset = debugTilesetImage(io: io),
              let tileMap = debugTileMapImage(io: io) else { return }

        writeCGImageToDisk(tileset, name: "tileset")
        writeCGImageToDisk(tileMap, name: "tileMap")
        writeVRAMDataToDisk()
    }

    func writeCGImageToDisk(_ image: CGImage, name: String) {
        let url = URL(fileURLWithPath: "Documents/\(name).png")
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypePNG, 1, nil) else { return }
        CGImageDestinationAddImage(destination, image, nil)
        _ = CGImageDestinationFinalize(destination)
    }

    func writeVRAMDataToDisk() {
        let dataURL = URL(fileURLWithPath: "Documents/tileset.data")
        let data = Data(bytes)
        try? data.write(to: dataURL)
    }

    func debugTilesetImage(io: IO) -> CGImage? {
        let tilesWide: UInt16 = 16
        let tilesTall: UInt16 = 24
        let tileSize: UInt16 = 8
        let width = tilesWide * tileSize
        let height = tilesTall * tileSize

        var bytes = [Byte]()
        for pixelIndex in (0..<(width * height)) {
            let pixelX = pixelIndex % width
            let pixelY = pixelIndex / width

            let tileX = pixelX / tileSize
            let tileY = pixelY / tileSize

            let pixelXInTile = pixelX % tileSize
            let pixelYInTile = pixelY % tileSize

            let tileNumber = tileY * tilesWide + tileX
            let tileAddress = 0x8000 + tileNumber * 0x10 // each tile is 0x10 bytes

            let pixelColorNumber = getPixelColorNumber(tileAddress: tileAddress, xOffsetInTile: pixelXInTile, yOffsetInTile: pixelYInTile)
            let grayValue = 255 - pixelColorNumber * 85
            bytes.append(contentsOf: [grayValue, grayValue, grayValue, .max])
        }

        return getImageFromRGBA(bytes: bytes, width: Int(width), height: Int(height))
    }

    func debugTileMapImage(io: IO) -> CGImage? {
        let tileSize = 8
        let width = 32 * tileSize
        let height = 32 * tileSize

        var bytes = [Byte]()
        for pixelIndex in (0..<(width * height)) {
            let pixelX = pixelIndex % width
            let pixelY = pixelIndex / width

            let tileX = pixelX / tileSize
            let tileY = pixelY / tileSize

            let pixelXInTile = pixelX % tileSize
            let pixelYInTile = pixelY % tileSize

            let bgTileIndex = tileY * 32 + tileX
            let bgTileAddress = Address(0x9800 + bgTileIndex)
            let tileNumber = read(address: bgTileAddress)
            let tileAddress = 0x8000 + Address(tileNumber) * 0x10

            let pixelColorNumber = getPixelColorNumber(tileAddress: tileAddress, xOffsetInTile: UInt16(pixelXInTile), yOffsetInTile: UInt16(pixelYInTile))
            let pixelColor = io.palettes.getColor(for: pixelColorNumber, in: .monochromeBackground)

            bytes.append(contentsOf: pixelColor.rgbaBytes)
        }

        return getImageFromRGBA(bytes: bytes, width: width, height: width)
    }

    // MARK: - Helpers

    private func getImageFromRGBA(bytes: [Byte], width: Int, height: Int) -> CGImage? {
        let _context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )

        if let context = _context, let data = context.data {
            _ = data.initializeMemory(as: Byte.self, from: bytes, count: bytes.count)
            return context.makeImage()
        } else {
            return nil
        }
    }

    private func getPixelColorNumber(tileAddress: Address, xOffsetInTile: UInt16, yOffsetInTile: UInt16) -> UInt8 {
        let pixelWord = readWord(address: tileAddress + yOffsetInTile * 2)
        let lowShift = 7 - xOffsetInTile
        let highShift = lowShift + 8 - 1
        let pixelColorNumber = (pixelWord >> highShift) & 0x02 | (pixelWord >> lowShift) & 0x01
        return UInt8(pixelColorNumber)
    }
}

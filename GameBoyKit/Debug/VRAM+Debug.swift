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

    public func debugTilesetImage(io: IO) -> CGImage? {
        let tilesWide: UInt16 = 16
        let tilesTall: UInt16 = 24
        let tileSize: UInt16 = 8
        let width = tilesWide * tileSize
        let height = tilesTall * tileSize
        let vramView = currentView

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
            let tile = Tile(dataAddress: tileAddress, bankNumber: .zero, isXFlipped: false, isYFlipped: false)

            let pixelColorNumber = tile.getColorNumber(vramView: vramView, xOffset: UInt8(pixelXInTile), yOffset: UInt8(pixelYInTile))
            let grayValue = 255 - pixelColorNumber * 85
            bytes.append(contentsOf: [grayValue, grayValue, grayValue, .max])
        }

        return getImageFromRGBA(bytes: bytes, width: Int(width), height: Int(height))
    }

    public func debugTileMapImage(io: IO) -> CGImage? {
        let tileSize = 8
        let width = 32 * tileSize
        let height = 32 * tileSize
        let paletteView = io.palettes.currentView
        let vramView = currentView

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
            let tileDataAddress = 0x8000 + Address(tileNumber) * 0x10
            let attributes = vramView.getAttributesForTileAddressInMap(bgTileAddress)

            let tile = Tile(dataAddress: tileDataAddress, bankNumber: attributes.tileVRAMBankNumber, isXFlipped: attributes.isXFlipped, isYFlipped: attributes.isYFlipped)
            let pixelColorNumber = tile.getColorNumber(vramView: vramView, xOffset: UInt8(pixelXInTile), yOffset: UInt8(pixelYInTile))
            let pixelColor = paletteView.getColor(number: pixelColorNumber, attributes: attributes)

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
}

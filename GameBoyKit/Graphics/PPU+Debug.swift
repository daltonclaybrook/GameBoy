extension PPU {
    func generateDebugOAMImage() -> CGImage {
        let objectSize = io.lcdControl.objectSize
        let objectCGSize = CGSize(width: CGFloat(objectSize.width), height: CGFloat(objectSize.height))

        let spritesPerRow = 8
        let rowsCount = 40 / spritesPerRow
        let padding = 8
        let fullWidth = spritesPerRow * Int(objectSize.width) + (spritesPerRow - 1) * padding
        let fullHeight = rowsCount * Int(objectSize.height) + (rowsCount - 1) * padding
        let context = createGraphicsContext(width: fullWidth, height: fullHeight)

        (0..<40).forEach { index in
            let sprite = oam.getSprite(atIndex: index)
            let tiles = getTiles(for: sprite, dataRange: io.lcdControl.tileDataForObjects)
            let spriteColorBytes = tiles.flatMap { getColorBytes(for: sprite, tile: $0) }
            let spriteImage = getCGImageFromSpriteColorBytes(spriteColorBytes)
            let xOffset = CGFloat(index % spritesPerRow)
            let yOffset = CGFloat(index / spritesPerRow)
            let xAdjustedOffset = xOffset * (objectCGSize.width + CGFloat(padding))
            let yAdjustedOffset = yOffset * (objectCGSize.height + CGFloat(padding))
            let rect = CGRect(x: xAdjustedOffset, y: yAdjustedOffset, width: objectCGSize.width, height: objectCGSize.height)
            context.draw(spriteImage, in: rect)
        }

        let scale: CGFloat = 2.0
        context.scaleBy(x: scale, y: scale)
        guard let image = context.makeImage() else {
            fatalError("Could not make image")
        }
        return image
    }

    func getTileNumbers(for sprite: SpriteAttributes) -> [TileNumber] {
        let tileNumber = sprite.tileNumber
        switch io.lcdControl.objectSize {
        case .small:
            return [tileNumber]
        case .large:
            return [
                tileNumber & 0xfe, // top tile
                tileNumber | 0x01 // bottom tile
            ]
        }
    }

    func getTiles(for sprite: SpriteAttributes, dataRange: LCDControl.TileDataRange) -> [Tile] {
        getTileNumbers(for: sprite).map { tileNumber in
            Tile(tileNumber: tileNumber, in: dataRange)
        }
    }

    func getColorBytes(for sprite: SpriteAttributes, tile: Tile) -> [Byte] {
        var colorBytes: [Byte] = []
        (UInt8(0)..<8).forEach { yOffset in
            (UInt8(0)..<8).forEach { xOffset in
                let colorNumber = tile.getColorNumber(in: vram, xOffset: xOffset, xFlipped: sprite.isXFlipped, yOffset: yOffset, yFlipped: sprite.isYFlipped)
                let color = io.palettes.getColor(for: colorNumber, in: sprite.monochromePalette)
                colorBytes.append(contentsOf: color.rgbaBytes)
            }
        }
        return colorBytes
    }

    func getCGImageFromSpriteColorBytes(_ colorBytes: [Byte]) -> CGImage {
        let objectSize = io.lcdControl.objectSize
        let context = createGraphicsContext(width: Int(objectSize.width), height: Int(objectSize.height))
        guard let data = context.data else {
            fatalError("Unable to create CGContext and data buffer")
        }

        data.initializeMemory(as: Byte.self, from: colorBytes, count: colorBytes.count)
        guard let image = context.makeImage() else {
            fatalError("Unable to create image")
        }

        return image
    }

    func createGraphicsContext(width: Int, height: Int) -> CGContext {
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            fatalError("Unable to create CGContext")
        }
        return context
    }
}

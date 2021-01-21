extension PPU {
    public func generateDebugOAMImage(scale: CGFloat) -> CGImage {
        let objectSize = io.lcdControl.objectSize
        let objectCGSize = CGSize(width: CGFloat(objectSize.width), height: CGFloat(objectSize.height))

        let spritesPerRow = 8
        let rowsCount = 40 / spritesPerRow
        let padding = 8
        let fullWidth = spritesPerRow * Int(objectSize.width) + (spritesPerRow - 1) * padding
        let fullHeight = rowsCount * Int(objectSize.height) + (rowsCount - 1) * padding
        let context = createGraphicsContext(width: fullWidth, height: fullHeight)
        context.setShouldAntialias(false)

        (0..<40).forEach { index in
            let sprite = oam.getSprite(atIndex: index)
            guard sprite.getIsOnScreen(objectSize: io.lcdControl.objectSize) else { return }

            let tiles = getTiles(for: sprite, dataRange: io.lcdControl.tileDataRangeForObjects)
            let spriteColorBytes = tiles.flatMap { getColorBytes(for: sprite, tile: $0) }
            let spriteImage = getCGImageFromSpriteColorBytes(spriteColorBytes)
            let xOffset = CGFloat(index % spritesPerRow)
            let yOffset = CGFloat(index / spritesPerRow)
            let xAdjustedOffset = xOffset * (objectCGSize.width + CGFloat(padding))
            let yAdjustedOffset = yOffset * (objectCGSize.height + CGFloat(padding))
            let rect = CGRect(x: xAdjustedOffset, y: yAdjustedOffset, width: objectCGSize.width, height: objectCGSize.height)
            context.draw(spriteImage, in: rect)
        }

        guard let image = context.makeImage() else {
            fatalError("Could not make image")
        }
        let scaledContext = createGraphicsContext(width: fullWidth * Int(scale), height: fullHeight * Int(scale))
        scaledContext.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(fullWidth) * scale, height: CGFloat(fullHeight) * scale))
        guard let scaledImage = scaledContext.makeImage() else {
            fatalError("Could not make scaled image")
        }
        return scaledImage
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
        getTileNumbers(for: sprite).map(dataRange.getTile(for:))
    }

    func getColorBytes(for sprite: SpriteAttributes, tile: Tile) -> [Byte] {
        var colorBytes: [Byte] = []
        (UInt8(0)..<8).forEach { yOffset in
            (UInt8(0)..<8).forEach { xOffset in
                let colorNumber = tile.getColorNumber(in: vram, xOffset: xOffset, xFlipped: sprite.isXFlipped, yOffset: yOffset, yFlipped: sprite.isYFlipped)
                if colorNumber == 0 {
                    // Color number 0 is transparent in sprites
                    colorBytes.append(contentsOf: Color.white)
                } else {
                    let color = io.palettes.getColor(for: colorNumber, in: sprite.monochromePalette)
                    colorBytes.append(contentsOf: color.rgbaBytes)
                }
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
        context.interpolationQuality = .none
        return context
    }
}

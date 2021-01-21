extension PPU {
    func generateDebugOAMImage() {
        (0..<40).forEach { index in
            let sprite = oam.getSprite(atIndex: index)
            let tiles = getTiles(for: sprite, dataRange: io.lcdControl.tileDataForObjects)


        }
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

    func getColorBytes(for tile: Tile, in palette: ColorPalettes.Palette) -> [Byte] {
        // todo: implement
        return []
    }
}

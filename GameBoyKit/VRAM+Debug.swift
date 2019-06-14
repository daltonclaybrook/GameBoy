import CoreGraphics

extension VRAM {
	func writeCGImageToDisk() {
		guard let image = debugTilesetImage() else { return }
		let url = URL(fileURLWithPath: "Documents/tileset_a.png")
		guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypePNG, 1, nil) else { return }
		CGImageDestinationAddImage(destination, image, nil)
		_ = CGImageDestinationFinalize(destination)

		let dataURL = URL(fileURLWithPath: "Documents/tileset.data")
		try? data.write(to: dataURL)
	}

	func debugTilesetImage() -> CGImage? {
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

			let tileIndex = tileY * tilesWide + tileX
			let tileAddress = 0x8000 + tileIndex * 0x10 // each tile is 0x10 bytes

			let pixelColorNumber = getPixelColorNumber(tileAddress: tileAddress, xOffsetInTile: pixelXInTile, yOffsetInTile: pixelYInTile)
			let grayValue = 255 - pixelColorNumber * 85
			bytes.append(contentsOf: [grayValue, grayValue, grayValue, .max])
		}

		return getImageFromRGBA(bytes: bytes, width: Int(width), height: Int(height))
	}

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

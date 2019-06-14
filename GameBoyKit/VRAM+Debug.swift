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
		let tilesWide = 16
		let tilesTall = 24
		let tileSize = 8
		let width = tilesWide * tileSize
		let height = tilesTall * tileSize
		let numComponents = 4 // 4 components (RGBA)

		var bytes = [Byte]()
		for pixelIndex in (0..<(width * height)) {
			let pixelY = pixelIndex / width
			let pixelX = pixelIndex % width

			let tileY = pixelY / tileSize
			let tileX = pixelX / tileSize
			let pixelXInTile = pixelX % tileSize
			let pixelYInTile = pixelY % tileSize

			let tileIndex = tileY * tilesWide + tileX
			let tileAddress = 0x8000 + tileIndex * 0x10 // each tile is 0x10 bytes

			let pixelWord = readWord(address: Address(tileAddress + pixelYInTile * 2))
			let shift = 7 - pixelXInTile
			let highShift = UInt16(truncatingIfNeeded: shift + 8 - 1)
			let lowShift = UInt16(truncatingIfNeeded: shift)
			let pixelBits = (pixelWord >> highShift) & 0x02 | (pixelWord >> lowShift) & 0x01

			let grayValue = UInt8(truncatingIfNeeded: 255 - pixelBits * 85)
			bytes.append(contentsOf: [grayValue, grayValue, grayValue, .max])
		}

		let _context = CGContext(
			data: nil,
			width: width,
			height: height,
			bitsPerComponent: 8,
			bytesPerRow: width * numComponents,
			space: CGColorSpaceCreateDeviceRGB(),
			bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
		)

		guard let context = _context, let data = context.data else { return nil }
		_ = data.initializeMemory(as: Byte.self, from: bytes, count: bytes.count)
		return context.makeImage()
	}
}

import MetalKit

public enum RendererError: Error {
	case failedToMakeTexture
	case failedToMakeCommandQueue
	case failedToLoadShaders
}

public final class Renderer: NSObject {
	private let view: MTKView
	private let device: MTLDevice
	private let texture: MTLTexture
	private let pipelineState: MTLRenderPipelineState
	private let commandQueue: MTLCommandQueue

	private var vertexBuffer: MTLBuffer?
	private var viewportSize: vector_uint2 = .zero
	private var numberOfVertices = 0

	public init(view: MTKView, device: MTLDevice) throws {
		self.view = view
		self.device = device

		let textureDescriptor = MTLTextureDescriptor()
		textureDescriptor.pixelFormat = .rgba8Unorm
		textureDescriptor.width = Constants.screenWidth
		textureDescriptor.height = Constants.screenHeight

		guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
			throw RendererError.failedToMakeTexture
		}
		self.texture = texture

		let library = try device.makeDefaultLibrary(bundle: Bundle(for: Renderer.self))
		guard let vertexFunction = library.makeFunction(name: "vertexShader"),
			let fragmentFunction = library.makeFunction(name: "samplingShader") else {
				throw RendererError.failedToLoadShaders
		}

		let pipelineDescriptor = MTLRenderPipelineDescriptor()
		pipelineDescriptor.label = "Texture Pipeline"
		pipelineDescriptor.vertexFunction = vertexFunction
		pipelineDescriptor.fragmentFunction = fragmentFunction
		pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
		pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)

		guard let commandQueue = device.makeCommandQueue() else {
			throw RendererError.failedToMakeCommandQueue
		}
		self.commandQueue = commandQueue

		super.init()
		view.delegate = self
		updateForDrawableSizeChange(view.drawableSize)
	}

	// MARK: - Helpers

	private func updateForDrawableSizeChange(_ size: CGSize) {
		let minSize = Float(min(size.width, size.height))
		viewportSize.x = UInt32(size.width)
		viewportSize.y = UInt32(size.height)

		let quadVertices: [AAPLVertex] = [
			AAPLVertex(position: vector_float2(minSize, -minSize), textureCoordinate: vector_float2(1.0, 1.0)),
			AAPLVertex(position: vector_float2(-minSize, -minSize), textureCoordinate: vector_float2(0.0, 1.0)),
			AAPLVertex(position: vector_float2(-minSize, minSize), textureCoordinate: vector_float2(0.0, 0.0)),

			AAPLVertex(position: vector_float2(minSize, -minSize), textureCoordinate: vector_float2(1.0, 1.0)),
			AAPLVertex(position: vector_float2(-minSize, minSize), textureCoordinate: vector_float2(0.0, 0.0)),
			AAPLVertex(position: vector_float2(minSize, minSize), textureCoordinate: vector_float2(1.0, 0.0))
		]
		numberOfVertices = quadVertices.count

		vertexBuffer = device.makeBuffer(
			bytes: quadVertices,
			length: quadVertices.count * MemoryLayout<AAPLVertex>.stride,
			options: .storageModeShared
		)
	}
}

extension Renderer: MTKViewDelegate {
	public func draw(in view: MTKView) {
		guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
		defer { commandBuffer.commit() }
		commandBuffer.label = "Draw Command"

		guard let renderPassDescriptor = view.currentRenderPassDescriptor,
			let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor),
			let vertexBuffer = vertexBuffer,
			let drawable = view.currentDrawable else { return }

		renderEncoder.label = "Render Encoder"
		renderEncoder.setRenderPipelineState(pipelineState)
		renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: Int(AAPLVertexInputIndexVertices.rawValue))
		renderEncoder.setVertexBytes([viewportSize], length: MemoryLayout<vector_uint2>.size, index: Int(AAPLVertexInputIndexViewportSize.rawValue))

//		renderEncoder.setFragmentTexture(, index: )

		renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: numberOfVertices)
		renderEncoder.endEncoding()
		commandBuffer.present(drawable)
	}

	public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
		updateForDrawableSizeChange(size)
	}
}

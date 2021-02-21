import MetalKit

public enum RendererError: Error {
    case failedToMakeTexture
    case failedToMakeCommandQueue
    case failedToLoadShaders
}

public struct PixelRegion {
    let x: Int
    let y: Int
    let width: Int
    let height: Int
}

public protocol Renderer {
    func render(pixelData: [Byte], at region: PixelRegion)
}

public final class MetalRenderer: NSObject, Renderer {
    private let view: MTKView
    private let device: MTLDevice
    private let texture: MTLTexture
    private let pipelineState: MTLRenderPipelineState
    private let commandQueue: MTLCommandQueue

    private var vertexBuffer: MTLBuffer?
    private var viewportSize: vector_uint2 = .zero
    private var numberOfVertices = 0
    private var currentCommandBuffer: MTLCommandBuffer?
    private var queuedTextureReplaceBlock: (() -> Void)?

    public init(view: MTKView, device: MTLDevice) throws {
        self.view = view
        self.device = device

        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .rgba8Unorm
        textureDescriptor.width = ScreenConstants.width
        textureDescriptor.height = ScreenConstants.height

        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            throw RendererError.failedToMakeTexture
        }
        self.texture = texture

        let library = try device.makeDefaultLibrary(bundle: Bundle(for: MetalRenderer.self))
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

    public func render(pixelData: [Byte], at region: PixelRegion) {
        DispatchQueue.main.async {
            guard let commandBuffer = self.currentCommandBuffer else {
                return self.replaceTextureRegion(with: pixelData, at: region)
            }

            switch commandBuffer.status {
            case .completed, .error:
                self.replaceTextureRegion(with: pixelData, at: region)
            default:
                self.queuedTextureReplaceBlock = { [weak self] in
                    self?.replaceTextureRegion(with: pixelData, at: region)
                }
            }
        }
    }

    // MARK: - Helpers

    private func replaceTextureRegion(with bytes: [Byte], at region: PixelRegion) {
        texture.replace(
            region: region.mtlRegion,
            mipmapLevel: 0,
            withBytes: bytes,
            bytesPerRow: 4 * ScreenConstants.width
        )
    }

    private func updateForDrawableSizeChange(_ size: CGSize) {
        let targetRatio = CGFloat(ScreenConstants.width) / CGFloat(ScreenConstants.height)
        let drawableRatio = size.width / size.height

        let vertexWidth: Float
        let vertexHeight: Float
        if drawableRatio < targetRatio {
            vertexWidth = Float(size.width) / 2
            vertexHeight = Float(size.width / targetRatio) / 2
        } else {
            vertexWidth = Float(size.height * targetRatio) / 2
            vertexHeight = Float(size.height) / 2
        }

        viewportSize.x = UInt32(size.width)
        viewportSize.y = UInt32(size.height)

        let quadVertices: [AAPLVertex] = [
            AAPLVertex(position: vector_float2(vertexWidth, -vertexHeight), textureCoordinate: vector_float2(1.0, 1.0)),
            AAPLVertex(position: vector_float2(-vertexWidth, -vertexHeight), textureCoordinate: vector_float2(0.0, 1.0)),
            AAPLVertex(position: vector_float2(-vertexWidth, vertexHeight), textureCoordinate: vector_float2(0.0, 0.0)),

            AAPLVertex(position: vector_float2(vertexWidth, -vertexHeight), textureCoordinate: vector_float2(1.0, 1.0)),
            AAPLVertex(position: vector_float2(-vertexWidth, vertexHeight), textureCoordinate: vector_float2(0.0, 0.0)),
            AAPLVertex(position: vector_float2(vertexWidth, vertexHeight), textureCoordinate: vector_float2(1.0, 0.0))
        ]
        numberOfVertices = quadVertices.count

        vertexBuffer = device.makeBuffer(
            bytes: quadVertices,
            length: quadVertices.count * MemoryLayout<AAPLVertex>.stride,
            options: .storageModeShared
        )
    }

    private func commandBufferCompleted() {
        currentCommandBuffer = nil
        queuedTextureReplaceBlock?()
        queuedTextureReplaceBlock = nil
    }
}

extension MetalRenderer: MTKViewDelegate {
    public func draw(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        defer { commandBuffer.commit() }
        commandBuffer.label = "Draw Command"

        currentCommandBuffer = commandBuffer
        commandBuffer.addCompletedHandler { [weak self] _ in
            DispatchQueue.main.async {
                self?.commandBufferCompleted()
            }
        }

        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor),
              let vertexBuffer = vertexBuffer,
              let drawable = view.currentDrawable else { return }

        renderEncoder.label = "Render Encoder"
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: Int(AAPLVertexInputIndexVertices.rawValue))
        renderEncoder.setVertexBytes([viewportSize], length: MemoryLayout<vector_uint2>.size, index: Int(AAPLVertexInputIndexViewportSize.rawValue))

        renderEncoder.setFragmentTexture(texture, index: Int(AAPLTextureIndexBaseColor.rawValue))

        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: numberOfVertices)
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        updateForDrawableSizeChange(size)
    }
}

extension PixelRegion {
    var mtlRegion: MTLRegion {
        let origin = MTLOrigin(x: x, y: y, z: 0)
        let size = MTLSize(width: width, height: height, depth: 1)
        return MTLRegion(origin: origin, size: size)
    }
}

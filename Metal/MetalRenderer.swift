import Metal
import MetalKit
import QuartzCore
import simd

final class MetalRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let uniformBuffer: MTLBuffer

    weak var viewModel: ExplorerViewModel?

    private var startTime: CFTimeInterval = CACurrentMediaTime()
    private var lastFrameTime: CFTimeInterval = CACurrentMediaTime()
    private var fpsSmoother = FPSSmoother()

    init(device: MTLDevice, viewModel: ExplorerViewModel) {
        self.device = device
        self.viewModel = viewModel

        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Failed to create MTLCommandQueue.")
        }
        self.commandQueue = commandQueue

        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to load default Metal library. Make sure the .metal file is in the target.")
        }

        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = library.makeFunction(name: "fullscreenVertex")
        pipelineDesc.fragmentFunction = library.makeFunction(name: "fractalFragment")
        pipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDesc)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }

        guard let uniformBuffer = device.makeBuffer(length: MemoryLayout<ShaderUniforms>.stride, options: [.storageModeShared]) else {
            fatalError("Failed to create uniform buffer.")
        }
        self.uniformBuffer = uniformBuffer

        super.init()
    }

    func attach(to view: MTKView) {
        // No-op for now; hook exists for future view-dependent setup.
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // `MetalInputView` already caps drawableSize; we just respond to the resulting size.
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let rpd = view.currentRenderPassDescriptor else {
            return
        }

        let now = CACurrentMediaTime()
        let dt = now - lastFrameTime
        lastFrameTime = now

        let fps = fpsSmoother.push(frameTime: dt)
        viewModel?.setFPS(fps)

        let t = Float(now - startTime)
        let resolution = SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height))

        let snap = viewModel?.stepFrame() ?? RenderSnapshot.default

        var uniforms = ShaderUniforms(
            uResolution: SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height)),
            uCameraPos: snap.position,
            uCameraDir: snap.cameraDir,
            uCameraUp: snap.cameraUp,
            uOffset: snap.offset,
            uLogScale: snap.logScale,
            uTime: Float(CACurrentMediaTime()),
            uLightDir: normalize(snap.lightDirection),
            uShadowSoftness: snap.shadowSoftness,
            uTrapColor: snap.trapColor,
            uBaseColor: snap.baseColor,
            uAmbientIntensity: snap.ambientIntensity
        )
        memcpy(uniformBuffer.contents(), &uniforms, MemoryLayout<ShaderUniforms>.stride)

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) else {
            return
        }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// MARK: - Shared uniforms/snapshots

struct ShaderUniforms {
    var uResolution: SIMD2<Float>
    var uCameraPos: SIMD3<Float>
    var uCameraDir: SIMD3<Float>
    var uCameraUp: SIMD3<Float>
    var uOffset: SIMD3<Float>
    var uLogScale: Float
    var uTime: Float

    // Lighting
    var uLightDir: SIMD3<Float>
    var uShadowSoftness: Float
    var uTrapColor: SIMD3<Float>
    var uBaseColor: SIMD3<Float>
    var uAmbientIntensity: Float
}

struct RenderSnapshot {
    var position: SIMD3<Float>
    var cameraDir: SIMD3<Float>
    var cameraUp: SIMD3<Float>
    var offset: SIMD3<Float>
    var logScale: Float

    // Lighting
    var lightDirection: SIMD3<Float>
    var shadowSoftness: Float
    var trapColor: SIMD3<Float>
    var baseColor: SIMD3<Float>
    var ambientIntensity: Float

    static let `default` = RenderSnapshot(
        position: SIMD3<Float>(0, 0, 4),
        cameraDir: SIMD3<Float>(0, 0, -1),
        cameraUp: SIMD3<Float>(0, 1, 0),
        offset: .zero,
        logScale: 0,
        lightDirection: SIMD3<Float>(0.5, 1.0, 0.3),
        shadowSoftness: 16.0,
        trapColor: SIMD3<Float>(0.9, 0.95, 1.0),
        baseColor: SIMD3<Float>(0.0, 0.6, 1.0),
        ambientIntensity: 0.2
    )
}

private struct FPSSmoother {
    private var smoothedFPS: Double = 0

    mutating func push(frameTime: CFTimeInterval) -> Double {
        guard frameTime > 0 else { return smoothedFPS }
        let instant = 1.0 / frameTime
        if smoothedFPS == 0 {
            smoothedFPS = instant
        } else {
            smoothedFPS = smoothedFPS * 0.9 + instant * 0.1
        }
        return smoothedFPS
    }
}

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

        var uniforms = ExplorerViewModel.Uniforms(
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
    var _pad: SIMD2<Float> = .zero
}

struct RenderSnapshot {
    var cameraPos: SIMD3<Float>
    var cameraDir: SIMD3<Float>
    var cameraUp: SIMD3<Float>
    var offset: SIMD3<Float>
    var logScale: Float

    static let `default` = RenderSnapshot(
        cameraPos: SIMD3<Float>(0, 0, 8),
        cameraDir: SIMD3<Float>(0, 0, -1),
        cameraUp: SIMD3<Float>(0, 1, 0),
        offset: .zero,
        logScale: 0
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

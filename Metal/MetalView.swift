import MetalKit
import SwiftUI

struct MetalView: NSViewRepresentable {
    @ObservedObject var viewModel: ExplorerViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeNSView(context: Context) -> MetalInputView {
        let mtkView = MetalInputView(frame: .zero, device: context.coordinator.device)
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        mtkView.colorspace = CGColorSpace(name: CGColorSpace.sRGB)
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        mtkView.framebufferOnly = true
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.preferredFramesPerSecond = 60

        mtkView.viewModel = viewModel
        mtkView.delegate = context.coordinator.renderer
        context.coordinator.renderer?.attach(to: mtkView)
        return mtkView
    }

    func updateNSView(_ nsView: MetalInputView, context: Context) {
        nsView.viewModel = viewModel
        context.coordinator.renderer?.viewModel = viewModel
    }

    final class Coordinator {
        let device: MTLDevice?
        let renderer: MetalRenderer?

        init(viewModel: ExplorerViewModel) {
            guard let device = MTLCreateSystemDefaultDevice() else {
                viewModel.setRendererErrorMessage("Metal is not supported on this Mac.")
                self.device = nil
                self.renderer = nil
                return
            }
            self.device = device
            self.renderer = MetalRenderer(device: device, viewModel: viewModel) { message in
                viewModel.setRendererErrorMessage(message)
            }
            if renderer != nil {
                viewModel.setRendererErrorMessage(nil)
            }
        }
    }
}

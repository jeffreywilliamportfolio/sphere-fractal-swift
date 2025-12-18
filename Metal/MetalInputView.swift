import AppKit
import CoreGraphics
import MetalKit

final class MetalInputView: MTKView {
    weak var viewModel: ExplorerViewModel? {
        didSet { syncCaptureState() }
    }

    private var trackingAreaRef: NSTrackingArea?
    private var cursorHidden = false
    private var isMouseAssociated = true

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.acceptsMouseMovedEvents = true
        updateTrackingAreas()

        NotificationCenter.default.addObserver(self, selector: #selector(windowDidResignKey), name: NSWindow.didResignKeyNotification, object: window)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidResignActive), name: NSApplication.didResignActiveNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        releaseMouseIfNeeded()
    }

    override func updateTrackingAreas() {
        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }

        let opts: NSTrackingArea.Options = [
            .activeInKeyWindow,
            .inVisibleRect,
            .mouseMoved,
            .enabledDuringMouseDrag
        ]
        let area = NSTrackingArea(rect: bounds, options: opts, owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingAreaRef = area

        super.updateTrackingAreas()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        updateDrawableSizeCapped()
    }

    override func layout() {
        super.layout()
        updateDrawableSizeCapped()
    }

    private func updateDrawableSizeCapped() {
        let scale = min(window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 1.0, 2.0)
        drawableSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)
    }

    // MARK: - Mouse capture

    private func syncCaptureState() {
        guard let viewModel else { return }
        if viewModel.isMouseCaptured {
            captureMouseIfNeeded()
        } else {
            releaseMouseIfNeeded()
        }
    }

    private func captureMouseIfNeeded() {
        guard !cursorHidden else { return }
        cursorHidden = true

        if isMouseAssociated {
            _ = CGAssociateMouseAndMouseCursorPosition(boolean_t(0))
            isMouseAssociated = false
        }
        NSCursor.hide()
        window?.makeFirstResponder(self)
    }

    private func releaseMouseIfNeeded() {
        guard cursorHidden else { return }
        cursorHidden = false

        if !isMouseAssociated {
            _ = CGAssociateMouseAndMouseCursorPosition(boolean_t(1))
            isMouseAssociated = true
        }
        NSCursor.unhide()
    }

    @objc private func windowDidResignKey() {
        releaseMouseIfNeeded()
        viewModel?.setMouseCaptured(false)
    }

    @objc private func appDidResignActive() {
        releaseMouseIfNeeded()
        viewModel?.setMouseCaptured(false)
    }

    // MARK: - NSEvent

    override func mouseDown(with event: NSEvent) {
        captureMouseIfNeeded()
        viewModel?.setMouseCaptured(true)
    }

    override func mouseMoved(with event: NSEvent) {
        guard viewModel?.isMouseCaptured == true else { return }
        viewModel?.addMouseDelta(dx: Float(event.deltaX), dy: Float(event.deltaY))
    }

    override func mouseDragged(with event: NSEvent) {
        mouseMoved(with: event)
    }

    override func scrollWheel(with event: NSEvent) {
        guard viewModel?.isMouseCaptured == true else { return }
        viewModel?.addScrollDelta(dy: Float(event.scrollingDeltaY))
    }

    override func flagsChanged(with event: NSEvent) {
        guard viewModel?.isMouseCaptured == true else { return }
        let sprinting = event.modifierFlags.contains(.shift)
        viewModel?.setSprinting(sprinting)
    }

    override func keyDown(with event: NSEvent) {
        guard let viewModel else { return }
        
        // Allow arrow-key look even when mouse capture is off (e.g., after pressing Esc).
        // Keep other movement keys gated behind capture so we don't interfere with UI typing.
        let code = event.keyCode
        let isArrowKey = (code == 123 || code == 124 || code == 125 || code == 126)
        guard viewModel.isMouseCaptured || isArrowKey else { return }

        if event.keyCode == 53 { // Esc
            releaseMouseIfNeeded()
            viewModel.setMouseCaptured(false)
            return
        }

        if !event.isARepeat {
            if event.keyCode == 4 { viewModel.toggleHelp() } // H
            if event.keyCode == 34 { viewModel.toggleStats() } // I
        }

        // Key Codes (US QWERTY standard, but generally consistent positionally for games)
        // W=13, S=1, A=0, D=2, Q=12, E=14
        switch code {
        case 13: viewModel.setKey("w", isDown: true)
        case 1:  viewModel.setKey("s", isDown: true)
        case 0:  viewModel.setKey("a", isDown: true)
        case 2:  viewModel.setKey("d", isDown: true)
        case 12: viewModel.setKey("q", isDown: true)
        case 14: viewModel.setKey("e", isDown: true)
        case 123: viewModel.setKey("leftArrow", isDown: true)
        case 124: viewModel.setKey("rightArrow", isDown: true)
        case 126: viewModel.setKey("upArrow", isDown: true)
        case 125: viewModel.setKey("downArrow", isDown: true)
        default: break
        }
    }

    override func keyUp(with event: NSEvent) {
        guard let viewModel else { return }
        
        let code = event.keyCode
        let isArrowKey = (code == 123 || code == 124 || code == 125 || code == 126)
        guard viewModel.isMouseCaptured || isArrowKey else { return }

        switch code {
        case 13: viewModel.setKey("w", isDown: false)
        case 1:  viewModel.setKey("s", isDown: false)
        case 0:  viewModel.setKey("a", isDown: false)
        case 2:  viewModel.setKey("d", isDown: false)
        case 12: viewModel.setKey("q", isDown: false)
        case 14: viewModel.setKey("e", isDown: false)
        case 123: viewModel.setKey("leftArrow", isDown: false)
        case 124: viewModel.setKey("rightArrow", isDown: false)
        case 126: viewModel.setKey("upArrow", isDown: false)
        case 125: viewModel.setKey("downArrow", isDown: false)
        default: break
        }
    }
}

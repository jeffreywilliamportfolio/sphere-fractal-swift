import Combine
import Foundation
import QuartzCore
import simd

final class ExplorerViewModel: ObservableObject {
    // MARK: - HUD state (SwiftUI reads these; update on main)
    
    @Published var showHelp: Bool = true
    @Published var showStats: Bool = true
    @Published var fps: Double = 0
    @Published var hudOffset: SIMD3<Float> = .zero
    @Published var hudLogScale: Float = 0
    @Published var hudSpeed: Float = Constants.moveSpeed
    @Published var isMouseCaptured: Bool = false
    @Published var isGamepadConnected: Bool = false
    @Published var isPrecisionMode: Bool = false
    
    @Published var bookmarks: [Bookmark] = []
    @Published var bookmarkDraftName: String = ""
    
    var canSaveBookmark: Bool {
        bookmarks.count < Constants.maxBookmarks
    }
    
    // MARK: - Internals
    
    private let lock = NSLock()
    private var nav = NavigationState()
    private var input = InputState()
    private var lastHUDUpdateTime: CFTimeInterval = 0
    private var lastFPSUpdateTime: CFTimeInterval = 0
    
    private let bookmarksKey = "AeternaSphere.bookmarks.v1"
    private var gamepadManager: GamepadManager?
    
    init() {
        loadBookmarks()
        gamepadManager = GamepadManager(viewModel: self)
    }
    
    // MARK: - Input (called from MetalInputView / GamepadManager)
    
    func setMouseCaptured(_ captured: Bool) {
        if Thread.isMainThread {
            isMouseCaptured = captured
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.isMouseCaptured = captured
            }
        }
        
        if !captured {
            lock.lock()
            defer { lock.unlock() }
            input.clearAll()
        }
    }
    
    func addMouseDelta(dx: Float, dy: Float) {
        lock.lock()
        defer { lock.unlock() }
        input.mouseDelta.x += dx
        input.mouseDelta.y += dy
    }
    
    func addScrollDelta(dy: Float) {
        lock.lock()
        defer { lock.unlock() }
        input.scrollDeltaY += dy
    }
    
    func setSprinting(_ sprinting: Bool) {
        lock.lock()
        defer { lock.unlock() }
        input.sprinting = sprinting
    }
    
    func setKey(_ chars: String, isDown: Bool) {
        lock.lock()
        defer { lock.unlock() }
        
        switch chars {
        case "w": input.setKey(.forward, isDown: isDown)
        case "s": input.setKey(.back, isDown: isDown)
        case "a": input.setKey(.left, isDown: isDown)
        case "d": input.setKey(.right, isDown: isDown)
        case "q": input.setKey(.down, isDown: isDown)
        case "e": input.setKey(.up, isDown: isDown)
        default: break
        }
    }
    
    func toggleHelp() {
        if Thread.isMainThread {
            showHelp.toggle()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.showHelp.toggle()
            }
        }
    }
    
    func toggleStats() {
        if Thread.isMainThread {
            showStats.toggle()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.showStats.toggle()
            }
        }
    }
    
    func setFPS(_ fps: Double) {
        let now = CACurrentMediaTime()
        if now - lastFPSUpdateTime < 0.15 { return }
        lastFPSUpdateTime = now
        if Thread.isMainThread {
            self.fps = fps
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.fps = fps
            }
        }
    }
    
    func setGamepadConnected(_ connected: Bool) {
        if Thread.isMainThread {
            isGamepadConnected = connected
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.isGamepadConnected = connected
            }
        }
    }
    
    func setGamepadState(leftX: Float, leftY: Float, rightX: Float, rightY: Float, leftTrigger: Float, rightTrigger: Float) {
        lock.lock()
        defer { lock.unlock() }
        input.gamepadLeft = SIMD2<Float>(leftX, leftY)
        input.gamepadRight = SIMD2<Float>(rightX, rightY)
        input.gamepadLT = leftTrigger
        input.gamepadRT = rightTrigger
    }
    
    // MARK: - Simulation step (called from renderer thread)
    
    func stepFrame() -> RenderSnapshot {
        let now = CACurrentMediaTime()
        
        // Copy & clear per-frame input with a single lock section.
        let frameState: (nav: NavigationState, input: InputState) = {
            lock.lock()
            defer { lock.unlock() }
            let nav = self.nav
            let input = self.input
            self.input.mouseDelta = .zero
            self.input.scrollDeltaY = 0
            return (nav: nav, input: input)
        }()
        
        var nav = frameState.nav
        let input = frameState.input
        
        // 0) Apply look deltas (mouse + gamepad).
        nav.yaw += input.mouseDelta.x * Constants.mouseSensitivity
        nav.pitch -= input.mouseDelta.y * Constants.mouseSensitivity
        
        nav.yaw += input.gamepadRight.x * Constants.gamepadLookSpeed
        nav.pitch += input.gamepadRight.y * Constants.gamepadLookSpeed
        
        nav.pitch = clamp(nav.pitch, -Constants.maxPitch, Constants.maxPitch)
        
        // 1) Build forward/right/up from yaw/pitch.
        let cp = cos(nav.pitch)
        let sp = sin(nav.pitch)
        let cy = cos(nav.yaw)
        let sy = sin(nav.yaw)
        let forward = SIMD3<Float>(sy * cp, sp, -cy * cp)
        let right = SIMD3<Float>(cy, 0, sy)
        let up = SIMD3<Float>(0, 1, 0)
        
        // Triggers continuously adjust base speed (per frame).
        nav.speed += (input.gamepadRT - input.gamepadLT) * Constants.speedTriggerDelta
        nav.speed = clamp(nav.speed, Constants.minSpeed, Constants.maxSpeed)
        
        var currentSpeed = nav.speed
        if input.sprinting { currentSpeed *= Constants.sprintMultiplier }
        if nav.precisionMode { currentSpeed *= Constants.precisionMultiplier }
        
        // 2) Compute moveX/moveY/moveZ from keyboard + gamepad axes.
        var moveX: Float = 0
        var moveY: Float = 0
        var moveZ: Float = 0
        
        moveX += input.isDown(.right) ? 1 : 0
        moveX -= input.isDown(.left) ? 1 : 0
        moveZ += input.isDown(.forward) ? 1 : 0
        moveZ -= input.isDown(.back) ? 1 : 0
        moveY += input.isDown(.up) ? 1 : 0
        moveY -= input.isDown(.down) ? 1 : 0
        
        moveX += input.gamepadLeft.x
        moveZ += input.gamepadLeft.y
        
        moveX = clamp(moveX, -1, 1)
        moveY = clamp(moveY, -1, 1)
        moveZ = clamp(moveZ, -1, 1)
        
        // 3) targetVel = (right*moveX + forward*moveZ)*speed, plus vertical from Q/E.
        var targetVel = (right * moveX + forward * moveZ) * currentSpeed
        targetVel += up * (moveY * currentSpeed)
        
        // 4) newVel = prevVel * DAMPING + targetVel * ACCELERATION
        var newVel = nav.velocity * Constants.damping + targetVel * Constants.acceleration
        
        // 8) Wheel zoom: add to velocity along forward.
        let impulse = -input.scrollDeltaY * Constants.scrollSensitivity
        if impulse != 0 {
            newVel += forward * impulse
        }
        
        // 5) newPos = prevPos + newVel
        var newPos = nav.position + newVel
        
        // 6) Clamp camera to within radius.
        let len = simd_length(newPos)
        if len > Constants.maxSphereRadius, len > 0 {
            newPos = (newPos / len) * Constants.maxSphereRadius
        }
        
        // 7) Floating-origin infinite navigation.
        let forwardMovement = -simd_dot(forward, newVel)
        if abs(forwardMovement) > 0.001 {
            let prevLogScale = nav.logScale
            let depthDelta = forwardMovement * 0.5
            nav.logScale = clamp(prevLogScale + depthDelta, -Constants.maxAbsLogScale, Constants.maxAbsLogScale)
            
            let scale = exp(prevLogScale)
            nav.offset += forward * forwardMovement * scale * 0.1
        }
        
        nav.velocity = newVel
        nav.position = newPos
        
        // Write back nav state.
        lock.lock()
        defer { lock.unlock() }
        self.nav = nav
        
        // Throttled HUD updates to avoid spamming SwiftUI.
        if now - lastHUDUpdateTime > 0.1 {
            lastHUDUpdateTime = now
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.hudOffset = nav.offset
                self.hudLogScale = nav.logScale
                self.hudSpeed = nav.speed
                self.isPrecisionMode = nav.precisionMode
            }
        }
        
        return RenderSnapshot(
            position: nav.position,
            cameraDir: forward,
            cameraUp: up,
            offset: nav.offset,
            logScale: nav.logScale,
            lightDirection: self.lightDirection,
            shadowSoftness: self.shadowSoftness,
            trapColor: self.trapColor,
            ambientIntensity: self.ambientIntensity
        )
    }
    
    // MARK: - Bookmarks
    
    func saveCurrentBookmark() {
        guard bookmarks.count < Constants.maxBookmarks else { return }
        
        let (offset, logScale) = currentOffsetAndLogScale()
        let trimmed = bookmarkDraftName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "Bookmark \(bookmarks.count + 1)" : trimmed
        let bm = Bookmark(name: name, offset: offset, logScale: logScale)
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.bookmarks.insert(bm, at: 0)
            self.bookmarkDraftName = ""
            self.persistBookmarks()
        }
    }
    
    func loadBookmark(_ bookmark: Bookmark) {
        lock.lock()
        defer { lock.unlock() }
        nav.offset = bookmark.offset.simd
        nav.logScale = bookmark.logScale
        nav.position = Constants.initialCameraPos
        nav.velocity = .zero
        nav.pitch = 0
        nav.yaw = 0
    }
    
    func deleteBookmark(_ bookmark: Bookmark) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.bookmarks.removeAll { $0.id == bookmark.id }
            self.persistBookmarks()
        }
    }
    
    private func loadBookmarks() {
        guard let data = UserDefaults.standard.data(forKey: bookmarksKey) else { return }
        let decoded: [Bookmark]
        do {
            decoded = try JSONDecoder().decode([Bookmark].self, from: data)
        } catch {
            decoded = []
        }
        
        if Thread.isMainThread {
            bookmarks = decoded
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.bookmarks = decoded
            }
        }
    }
    
    private func persistBookmarks() {
        do {
            let data = try JSONEncoder().encode(bookmarks)
            UserDefaults.standard.set(data, forKey: bookmarksKey)
        } catch {
            // Ignore persistence errors for now.
        }
    }
    
    private func currentOffsetAndLogScale() -> (SIMD3<Float>, Float) {
        lock.lock()
        defer { lock.unlock() }
        let offset = nav.offset
        let logScale = nav.logScale
        return (offset, logScale)
    }
    
    // MARK: - Actions
    
    func resetToOrigin() {
        do {
            lock.lock()
            defer { lock.unlock() }
            nav = NavigationState()
            input.clearAll()
        }
        DispatchQueue.main.async { [weak self] in
            self?.isPrecisionMode = false
        }
    }
    
    func togglePrecisionMode() {
        let newValue: Bool = {
            lock.lock()
            DispatchQueue.main.async { [weak self] in
                self?.isPrecisionMode = newValue
            }
        }
        
        // MARK: - Advanced Lighting
        @Published var lightDirection: SIMD3<Float> = SIMD3<Float>(0.5, 1.0, 0.3)
        @Published var shadowSoftness: Float = 16.0
        @Published var trapColor: SIMD3<Float> = SIMD3<Float>(1.0, 0.5, 0.0) // Orange glow
        @Published var ambientIntensity: Float = 0.2
        
        // MARK: - Internal
        private var cancellables = Set<AnyCancellable>()
        private var gamepadManager = GamepadManager()
        private let navLock = NSLock()
        
        // Shader Uniforms (Must match Metal struct alignment)
        struct Uniforms {
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
            var uAmbientIntensity: Float
        }
    }
    
    // MARK: - State structs
    
    private struct NavigationState {
        // Navigation model (matches the prompt semantics)
        var offset: SIMD3<Float> = .zero
        var logScale: Float = 0
        var position: SIMD3<Float> = Constants.initialCameraPos
        var pitch: Float = 0
        var yaw: Float = 0
        var velocity: SIMD3<Float> = .zero
        var speed: Float = Constants.moveSpeed
        var precisionMode: Bool = false
    }
    
    private struct InputState {
        var keys: UInt16 = 0
        var sprinting: Bool = false
        var mouseDelta: SIMD2<Float> = .zero
        var scrollDeltaY: Float = 0
        
        var gamepadLeft: SIMD2<Float> = .zero
        var gamepadRight: SIMD2<Float> = .zero
        var gamepadLT: Float = 0
        var gamepadRT: Float = 0
        
        mutating func clearAll() {
            keys = 0
            sprinting = false
            mouseDelta = .zero
            scrollDeltaY = 0
            gamepadLeft = .zero
            gamepadRight = .zero
            gamepadLT = 0
            gamepadRT = 0
        }
        
        mutating func setKey(_ key: Key, isDown: Bool) {
            if isDown {
                keys |= key.rawValue
            } else {
                keys &= ~key.rawValue
            }
        }
        
        func isDown(_ key: Key) -> Bool {
            (keys & key.rawValue) != 0
        }
        
        enum Key: UInt16 {
            case forward = 1
            case back = 2
            case left = 4
            case right = 8
            case up = 16
            case down = 32
        }
    }
    
    private enum Constants {
        static let moveSpeed: Float = 0.05
        static let sprintMultiplier: Float = 3.0
        static let damping: Float = 0.85
        static let acceleration: Float = 0.3
        static let maxSphereRadius: Float = 4.5
        static let scrollSensitivity: Float = 0.000375
        static let mouseSensitivity: Float = 0.002
        static let gamepadLookSpeed: Float = 0.05
        static let speedTriggerDelta: Float = 0.001
        static let minSpeed: Float = 0.01
        static let maxSpeed: Float = 0.2
        static let precisionMultiplier: Float = 0.3
        static let maxPitch: Float = 1.54
        static let maxAbsLogScale: Float = 60
        static let maxBookmarks: Int = 10
        static let initialCameraPos = SIMD3<Float>(0, 0, 4)
    }
    
    @inline(__always)
    private func clamp(_ x: Float, _ a: Float, _ b: Float) -> Float {
        min(max(x, a), b)
    }
}


import Foundation
import GameController

final class GamepadManager {
    private weak var viewModel: ExplorerViewModel?
    private var controller: GCController?

    init(viewModel: ExplorerViewModel) {
        self.viewModel = viewModel

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidConnect(_:)),
            name: .GCControllerDidConnect,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidDisconnect(_:)),
            name: .GCControllerDidDisconnect,
            object: nil
        )

        GCController.startWirelessControllerDiscovery(completionHandler: nil)
        if let existing = GCController.controllers().first {
            attach(existing)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        GCController.stopWirelessControllerDiscovery()
    }

    @objc private func controllerDidConnect(_ note: Notification) {
        guard let c = note.object as? GCController else { return }
        attach(c)
    }

    @objc private func controllerDidDisconnect(_ note: Notification) {
        guard let c = note.object as? GCController else { return }
        guard c == controller else { return }
        controller = nil

        viewModel?.setGamepadConnected(false)
        viewModel?.setGamepadState(leftX: 0, leftY: 0, rightX: 0, rightY: 0, leftTrigger: 0, rightTrigger: 0)
    }

    private func attach(_ c: GCController) {
        controller = c
        viewModel?.setGamepadConnected(true)

        guard let gp = c.extendedGamepad else { return }

        gp.valueChangedHandler = { [weak self] gamepad, _ in
            self?.pushState(from: gamepad)
        }

        gp.buttonA.pressedChangedHandler = { [weak self] _, _, pressed in
            guard pressed else { return }
            self?.viewModel?.resetToOrigin()
        }

        gp.buttonB.pressedChangedHandler = { [weak self] _, _, pressed in
            guard pressed else { return }
            self?.viewModel?.togglePrecisionMode()
        }

        pushState(from: gp)
    }

    private func pushState(from gp: GCExtendedGamepad) {
        let leftX = deadzone(gp.leftThumbstick.xAxis.value)
        let leftY = deadzone(gp.leftThumbstick.yAxis.value)
        let rightX = deadzone(gp.rightThumbstick.xAxis.value)
        let rightY = deadzone(gp.rightThumbstick.yAxis.value)
        let lt = max(0, gp.leftTrigger.value)
        let rt = max(0, gp.rightTrigger.value)

        viewModel?.setGamepadState(
            leftX: leftX,
            leftY: leftY,
            rightX: rightX,
            rightY: rightY,
            leftTrigger: lt,
            rightTrigger: rt
        )
    }

    private func deadzone(_ v: Float) -> Float {
        let dz: Float = 0.1
        return abs(v) < dz ? 0 : v
    }
}

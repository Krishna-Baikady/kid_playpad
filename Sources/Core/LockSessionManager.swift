import Foundation
import SwiftUI
import AppKit

/// Represents the active phase of the locking session
public enum LockPhase {
    /// Play phase: 2 minutes (0-120s) - Spawns exact typed alphabet letters or geometric shapes
    case phase1
    /// Wind-down phase: 1 minute (120-180s) - Continuous moving hand waving goodbye mascot & shapes ceased
    case phase2
    /// Session expired (180s+)
    case timeout
}

/// Coordinates the session timer, countdown, phase transitions, and active visual items.
public final class LockSessionManager: ObservableObject {
    public static let shared = LockSessionManager()

    // 3-Minute Configuration: 2 minutes play + 1 minute (60s) wind down = 3 minutes total (180 seconds)
    public let phase1Duration: TimeInterval = 120         // 2 minutes of letter/shape display
    public let totalSessionDuration: TimeInterval = 180   // 3 minutes total
    public let warningLeadTime: TimeInterval = 30         // Window appears 30 seconds before session ends (at 150s)

    @Published public private(set) var elapsedSeconds: TimeInterval = 0
    @Published public private(set) var currentPhase: LockPhase = .phase1
    @Published public private(set) var activeVisuals: [VisualItem] = []
    @Published public private(set) var showWarningAlert: Bool = false
    @Published public private(set) var warningSecondsRemaining: Int = 30

    /// Callback invoked when the 30-second warning countdown reaches 0
    public var onSessionExpired: (() -> Void)?

    private var timer: Timer?

    private init() {}

    /// Countdown minute displayed on the top-left (e.g. 2 during minute 1, 1 during minute 2)
    public var countdownMinutes: Int {
        let remaining = totalSessionDuration - elapsedSeconds
        if remaining <= 0 { return 1 }
        return max(1, Int(ceil(remaining / 60.0)))
    }

    /// Starts a fresh session.
    public func startSession() {
        stopSession()
        elapsedSeconds = 0
        currentPhase = .phase1
        activeVisuals.removeAll()
        showWarningAlert = false
        warningSecondsRemaining = Int(warningLeadTime)

        // Lock both keyboard and mouse
        EventTapManager.shared.setMouseInterception(enabled: true)

        let t = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timerTick()
        }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
    }

    /// Extends the session and returns to Phase 1.
    public func addTime() {
        showWarningAlert = false
        elapsedSeconds = 0
        currentPhase = .phase1
        activeVisuals.removeAll()
        warningSecondsRemaining = Int(warningLeadTime)

        // Re-lock mouse while keeping keyboard locked
        EventTapManager.shared.setMouseInterception(enabled: true)
        EventTapManager.shared.resume()
        KioskManager.shared.enableKioskMode()

        if timer == nil {
            let t = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.timerTick()
            }
            RunLoop.main.add(t, forMode: .common)
            self.timer = t
        }
    }

    /// Stops the timer and clears active visuals.
    public func stopSession() {
        timer?.invalidate()
        timer = nil
    }

    private func timerTick() {
        elapsedSeconds += 1

        // Phase determination
        if elapsedSeconds < phase1Duration {
            currentPhase = .phase1
        } else if elapsedSeconds < totalSessionDuration {
            currentPhase = .phase2
        } else {
            currentPhase = .timeout
        }

        let remaining = totalSessionDuration - elapsedSeconds

        // Trigger warning alert 30 seconds before the session ends (at t = 90s)
        if remaining <= warningLeadTime && remaining > 0 {
            warningSecondsRemaining = Int(remaining)
            if !showWarningAlert {
                showWarningAlert = true
                // Requirement 2: Unlock mouse so options can be clicked, BUT keep keyboard locked
                EventTapManager.shared.setMouseInterception(enabled: false)
            }
        } else if remaining <= 0 {
            warningSecondsRemaining = 0
            stopSession()
            onSessionExpired?()
        }
    }

    /// Handles an intercepted keystroke by generating the phase-appropriate visual.
    /// In Phase 1: Letter keys display that exact letter; any other key displays a geometric shape.
    /// In Phase 2: Spawns an extra floating waving hand ripple while the main waving mascot waves continuously.
    public func handleKeystroke(pressedChar: String?) {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let minX = screenFrame.minX + 120
        let maxX = screenFrame.maxX - 120
        let minY = screenFrame.minY + 120
        let maxY = screenFrame.maxY - 120

        let randomX = CGFloat.random(in: minX...maxX)
        let randomY = CGFloat.random(in: minY...maxY)
        let position = CGPoint(x: randomX, y: randomY)
        let color = MutedPalette.randomColor()

        switch currentPhase {
        case .phase1:
            let content: VisualContent

            // Check if the pressed key is an alphabet letter
            if let char = pressedChar,
               let firstScalar = char.uppercased().unicodeScalars.first,
               CharacterSet.letters.contains(firstScalar) {
                let letter = String(char.uppercased().prefix(1))
                content = .alphabet(character: letter)
            } else {
                // Any other key produces a calm geometric shape
                let shape = ShapeKind.allCases.randomElement() ?? .circle
                content = .shape(kind: shape)
            }

            let item = VisualItem(content: content, color: color, position: position, size: 120)
            spawnVisualItem(item)

        case .phase2:
            // Spawn an extra floating waving hand ripple
            let waveItem = VisualItem(
                content: .handWave,
                color: MutedPalette.randomColor(),
                position: position,
                size: 130
            )
            spawnVisualItem(waveItem)

        case .timeout:
            break
        }
    }

    private func spawnVisualItem(_ item: VisualItem) {
        if activeVisuals.count > 12 {
            activeVisuals.removeFirst()
        }

        activeVisuals.append(item)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) { [weak self] in
            guard let self = self else { return }
            if let index = self.activeVisuals.firstIndex(where: { $0.id == item.id }) {
                withAnimation(.easeOut(duration: 0.5)) {
                    _ = self.activeVisuals.remove(at: index)
                }
            }
        }
    }
}

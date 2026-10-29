import AppKit
import SwiftUI
import Combine

/// Main Application Delegate coordinating the secure keyboard lock lifecycle,
/// kiosk modes, accessibility permission checks, and clean fail-safe teardown.
public final class AppDelegate: NSObject, NSApplicationDelegate {
    public static private(set) weak var sharedInstance: AppDelegate?

    private var cancellables = Set<AnyCancellable>()

    public override init() {
        super.init()
        AppDelegate.sharedInstance = self
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        setupSignalHandlers()
        setupEventTapCallbacks()
        setupSessionObservers()

        // Hide dock icon if desired or run as regular application
        NSApp.setActivationPolicy(.regular)

        checkPermissionsAndStart()
    }

    private func checkPermissionsAndStart() {
        if AccessibilityHelper.isProcessTrusted() {
            startLockSession()
        } else {
            // Display permission onboarding window
            PermissionWindowController.shared.showPrompt(
                onAuthorized: { [weak self] in
                    self?.startLockSession()
                },
                onQuit: { [weak self] in
                    self?.performCleanUnlock()
                }
            )
        }
    }

    /// Engages total keyboard interception, kiosk shortcut blocking, and fullscreen visuals
    public func startLockSession() {
        // 1. Start event tap
        let tapSuccess = EventTapManager.shared.startIntercepting()
        guard tapSuccess else {
            print("Failed to initiate event tap. Showing permission prompt.")
            PermissionWindowController.shared.showPrompt(
                onAuthorized: { [weak self] in
                    self?.startLockSession()
                },
                onQuit: { [weak self] in
                    self?.performCleanUnlock()
                }
            )
            return
        }

        // 2. Enable Kiosk Mode (disables Cmd+Tab, Option+Cmd+Esc, Apple Menu, Dock, Menu Bar)
        KioskManager.shared.enableKioskMode()

        // 3. Show full-screen transparent overlay and hidden 20x20 unlock hit target
        OverlayWindowController.shared.showOverlay()

        // 4. Start 3-minute session timer (2 mins play + 1 min goodbye)
        LockSessionManager.shared.startSession()

        print("Kid PlayPad lock successfully engaged.")
    }

    private func setupEventTapCallbacks() {
        // Unlock Chord: Cmd + Option + Ctrl + U
        EventTapManager.shared.onUnlockChordDetected = { [weak self] in
            print("Unlock chord detected.")
            self?.performCleanUnlock()
        }

        // Keystroke intercepted: trigger Phase 1 or Phase 2 visuals
        EventTapManager.shared.onKeystrokeIntercepted = { pressedChar in
            LockSessionManager.shared.handleKeystroke(pressedChar: pressedChar)
        }
    }

    private func setupSessionObservers() {
        // Observe 30-second warning alert trigger (appears 30s before session ends)
        LockSessionManager.shared.$showWarningAlert
            .receive(on: DispatchQueue.main)
            .sink { [weak self] showAlert in
                if showAlert {
                    self?.displayTimeoutAlert()
                } else {
                    TimeoutAlertWindowController.shared.closeAlert()
                }
            }
            .store(in: &cancellables)

        // Automatic clean unlock when the 30-second countdown reaches 0
        LockSessionManager.shared.onSessionExpired = { [weak self] in
            print("Session time expired. Unlocking...")
            self?.performCleanUnlock()
        }
    }

    private func displayTimeoutAlert() {
        TimeoutAlertWindowController.shared.showAlert(
            onAddTime: {
                LockSessionManager.shared.addTime()
            },
            onUnlock: { [weak self] in
                self?.performCleanUnlock()
            }
        )
    }

    /// Restores all system configurations, presentation options, and exits cleanly.
    public func performCleanUnlock() {
        print("Performing clean unlock and teardown...")

        // 1. Stop lock timer
        LockSessionManager.shared.stopSession()

        // 2. Cleanly stop and release CGEventTap and restore mouse
        EventTapManager.shared.stop()
        MouseLockManager.shared.unlockMouse()

        // 3. Restore all presentation options (Dock, Menu Bar, Process Switching, Force Quit)
        KioskManager.shared.disableKioskMode()

        // 4. Close windows
        OverlayWindowController.shared.closeOverlay()
        TimeoutAlertWindowController.shared.closeAlert()
        PermissionWindowController.shared.closePrompt()

        // 5. Terminate app
        NSApp.terminate(nil)
    }

    private func setupSignalHandlers() {
        // Intercept SIGINT / SIGTERM for safe terminal exits
        signal(SIGINT) { _ in
            DispatchQueue.main.async {
                AppDelegate.sharedInstance?.performCleanUnlock()
            }
        }
        signal(SIGTERM) { _ in
            DispatchQueue.main.async {
                AppDelegate.sharedInstance?.performCleanUnlock()
            }
        }
    }

    public func applicationWillTerminate(_ notification: Notification) {
        // Guaranteed fail-safe restoration if closed through any external signal
        KioskManager.shared.disableKioskMode()
        EventTapManager.shared.stop()
        MouseLockManager.shared.unlockMouse()
    }
}

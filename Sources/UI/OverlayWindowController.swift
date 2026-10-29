import AppKit
import SwiftUI

/// Coordinates the transparent full-screen overlay windows across connected displays.
/// Covers all active screens to present Phase 1 & 2 visuals while absorbing all mouse events.
public final class OverlayWindowController {
    public static let shared = OverlayWindowController()

    private var overlayWindows: [NSWindow] = []

    private init() {}

    /// Displays the full-screen transparent overlay across all connected screens.
    public func showOverlay() {
        closeOverlay()

        let screens = NSScreen.screens.isEmpty ? [NSScreen.main].compactMap { $0 } : NSScreen.screens

        for screen in screens {
            let screenFrame = screen.frame

            // Fullscreen transparent overlay window at screen saver level
            let overlayWindow = NSWindow(
                contentRect: screenFrame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )

            overlayWindow.level = .screenSaver
            overlayWindow.backgroundColor = .clear
            overlayWindow.isOpaque = false
            overlayWindow.hasShadow = false
            // Absorbs any stray mouse clicks at window level
            overlayWindow.ignoresMouseEvents = false
            overlayWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

            let hostingView = NSHostingView(rootView: OverlayVisualView())
            hostingView.frame = screenFrame
            overlayWindow.contentView = hostingView
            overlayWindow.orderFrontRegardless()
            overlayWindows.append(overlayWindow)
        }
    }

    /// Closes all overlay windows cleanly.
    public func closeOverlay() {
        for window in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
    }
}

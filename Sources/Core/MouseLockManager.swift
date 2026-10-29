import AppKit
import CoreGraphics

/// Manages freezing and hiding the macOS mouse cursor during locked sessions.
/// Disconnects physical mouse motion from cursor position and hides the cursor icon.
public final class MouseLockManager {
    public static let shared = MouseLockManager()

    public private(set) var isMouseLocked: Bool = false

    private init() {}

    /// Freezes the mouse cursor and completely hides it from the display.
    public func lockMouse() {
        guard !isMouseLocked else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.isMouseLocked else { return }

            // 1. Disassociate physical mouse hardware movements from the on-screen cursor
            CGAssociateMouseAndMouseCursorPosition(boolean_t(0))

            // 2. Hide both the hardware cursor and AppKit cursor
            CGDisplayHideCursor(CGMainDisplayID())
            NSCursor.hide()

            self.isMouseLocked = true
        }
    }

    /// Re-associates physical mouse movements and restores cursor visibility.
    public func unlockMouse() {
        guard isMouseLocked else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isMouseLocked else { return }

            // 1. Reconnect physical mouse movement to the cursor
            CGAssociateMouseAndMouseCursorPosition(boolean_t(1))

            // 2. Unhide the hardware and AppKit cursor
            CGDisplayShowCursor(CGMainDisplayID())
            NSCursor.unhide()

            self.isMouseLocked = false
        }
    }

    deinit {
        if isMouseLocked {
            CGAssociateMouseAndMouseCursorPosition(boolean_t(1))
            CGDisplayShowCursor(CGMainDisplayID())
            NSCursor.unhide()
        }
    }
}

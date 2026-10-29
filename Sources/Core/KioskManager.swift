import AppKit

/// Manages system-level kiosk presentation options to strictly block macOS shortcuts
/// (Cmd+Tab, Cmd+Space, Cmd+Q, Option+Cmd+Esc, Apple Menu, Dock, Menu Bar) in-memory
/// without permanently touching any system configuration files or property lists.
public final class KioskManager {
    public static let shared = KioskManager()

    private var previousOptions: NSApplication.PresentationOptions = []
    public private(set) var isKioskActive: Bool = false

    private init() {}

    /// Activates aggressive kiosk mode blocking process switching, force quit,
    /// session termination, the Apple menu, Dock, and Menu Bar.
    public func enableKioskMode() {
        guard !isKioskActive else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.previousOptions = NSApp.presentationOptions

            let kioskOptions: NSApplication.PresentationOptions = [
                .disableProcessSwitching,    // Blocks Cmd+Tab, Dock app switching
                .disableForceQuit,           // Blocks Option+Cmd+Esc
                .disableSessionTermination,  // Blocks Log Out, Restart, Shut Down dialogs
                .disableAppleMenu,           // Disables Apple menu bar access
                .hideDock,                   // Keeps the Dock completely hidden
                .hideMenuBar                 // Keeps the Menu Bar completely hidden
            ]

            NSApp.presentationOptions = kioskOptions
            self.isKioskActive = true
        }
    }

    /// Restores the default system presentation options cleanly.
    public func disableKioskMode() {
        guard isKioskActive else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            NSApp.presentationOptions = self.previousOptions.isEmpty ? [] : self.previousOptions
            self.isKioskActive = false
        }
    }

    deinit {
        // Fail-safe restoration
        if isKioskActive {
            DispatchQueue.main.async {
                NSApp.presentationOptions = []
            }
        }
    }
}

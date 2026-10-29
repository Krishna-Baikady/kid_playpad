import Foundation
import ApplicationServices
import AppKit

/// Helper to check, test, and prompt for macOS Accessibility permissions required by CGEventTap.
public enum AccessibilityHelper {
    /// Checks whether the process is currently authorized for accessibility.
    /// Combines AXIsProcessTrusted() with a live event tap probe to bypass macOS permission caching bugs.
    public static func isProcessTrusted() -> Bool {
        // Fast path: system API check
        if AXIsProcessTrusted() {
            return true
        }

        // Live probe path: macOS caches AXIsProcessTrusted() per-process,
        // so toggling permission in System Settings while running might still report false.
        // Attempting to create a probe event tap directly queries the WindowServer for live authorization.
        let probeMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
        if let probePort = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: probeMask,
            callback: { _, _, event, _ in Unmanaged.passUnretained(event) },
            userInfo: nil
        ) {
            CFMachPortInvalidate(probePort)
            return true
        }

        return false
    }

    /// Triggers the system modal prompt asking the user to grant Accessibility permissions.
    @discardableResult
    public static func requestAccessibilityPermission() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Directly opens the Privacy & Security -> Accessibility settings pane in macOS System Settings.
    public static func openSystemSettingsAccessibility() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Determines if the current process is running as a proper signed .app bundle
    public static var isRunningAsAppBundle: Bool {
        return Bundle.main.bundleURL.pathExtension == "app"
    }

    /// Human-friendly name of what needs to be enabled in System Settings
    public static var targetDisplayName: String {
        if isRunningAsAppBundle {
            return "Kid PlayPad"
        } else {
            // Running as CLI binary inside Terminal / iTerm / IDE
            let processName = ProcessInfo.processInfo.processName
            return "Terminal (or \(processName))"
        }
    }

    /// Relaunches the application cleanly so macOS TCC completely refreshes permissions
    public static func relaunch() {
        let bundleURL = Bundle.main.bundleURL
        if isRunningAsAppBundle {
            let config = NSWorkspace.OpenConfiguration()
            config.createsNewApplicationInstance = true
            NSWorkspace.shared.openApplication(at: bundleURL, configuration: config) { _, _ in
                DispatchQueue.main.async {
                    NSApp.terminate(nil)
                }
            }
        } else {
            // If running via terminal binary, restart using Process
            let executablePath = CommandLine.arguments[0]
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = Array(CommandLine.arguments.dropFirst())
            try? process.run()
            NSApp.terminate(nil)
        }
    }

    /// Resets the stale TCC entry for Kid PlayPad so macOS prompts cleanly
    public static func resetTCC() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        process.arguments = ["reset", "Accessibility", "com.kidplaypad.app"]
        try? process.run()
        process.waitUntilExit()
    }
}

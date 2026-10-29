import Foundation
import CoreGraphics
import AppKit

/// Handles low-level global keyboard and mouse interception using CGEventTap.
/// Drops all keyboard and mouse inputs while safely monitoring for the unlock chord (Cmd + Option + Ctrl + U).
public final class EventTapManager {
    public static let shared = EventTapManager()

    private var machPort: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    public private(set) var isIntercepting: Bool = false
    public var isMouseInterceptionEnabled: Bool = true

    /// Invoked whenever the unlock chord (Cmd + Option + Ctrl + U) is pressed
    public var onUnlockChordDetected: (() -> Void)?

    /// Invoked whenever an intercepted key down occurs, to trigger visual feedback
    public var onKeystrokeIntercepted: ((String?) -> Void)?

    private init() {}

    /// Toggles mouse interception without altering keyboard interception
    public func setMouseInterception(enabled: Bool) {
        self.isMouseInterceptionEnabled = enabled
        if enabled {
            MouseLockManager.shared.lockMouse()
        } else {
            MouseLockManager.shared.unlockMouse()
        }
    }

    /// Starts global keyboard and mouse interception. Returns true on success, false if permissions are lacking.
    public func startIntercepting() -> Bool {
        guard !isIntercepting else { return true }

        // Explicit event types: keyboard, mouse, and system media/function events (13, 14, 15)
        let eventRawTypes: [Int] = [
            Int(CGEventType.keyDown.rawValue),
            Int(CGEventType.keyUp.rawValue),
            Int(CGEventType.flagsChanged.rawValue),
            13, // NX_KITDEFINED
            14, // NX_SYSDEFINED (media keys: Volume, Play/Pause, Brightness, Mute)
            15, // NX_APPDEFINED
            Int(CGEventType.leftMouseDown.rawValue),
            Int(CGEventType.leftMouseUp.rawValue),
            Int(CGEventType.rightMouseDown.rawValue),
            Int(CGEventType.rightMouseUp.rawValue),
            Int(CGEventType.otherMouseDown.rawValue),
            Int(CGEventType.otherMouseUp.rawValue),
            Int(CGEventType.mouseMoved.rawValue),
            Int(CGEventType.leftMouseDragged.rawValue),
            Int(CGEventType.rightMouseDragged.rawValue),
            Int(CGEventType.otherMouseDragged.rawValue),
            Int(CGEventType.scrollWheel.rawValue)
        ]

        var combinedMask: CGEventMask = 0
        for raw in eventRawTypes {
            combinedMask |= (CGEventMask(1) << raw)
        }

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        // Create the event tap at the hardware HID level first (captures raw media keys before macOS daemons),
        // falling back to session level if needed.
        let port = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: combinedMask,
            callback: eventTapCallback,
            userInfo: selfPointer
        ) ?? CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: combinedMask,
            callback: eventTapCallback,
            userInfo: selfPointer
        )

        guard let port = port else {
            print("Failed to create CGEventTap. Ensure Accessibility permissions are granted.")
            return false
        }

        self.machPort = port

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        self.runLoopSource = source

        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
        self.isIntercepting = true

        // Lock and hide the physical mouse cursor
        MouseLockManager.shared.lockMouse()

        return true
    }

    /// Temporarily pauses keyboard and mouse interception (e.g. for the session timeout alert).
    public func pause() {
        guard isIntercepting, let port = machPort else { return }
        CGEvent.tapEnable(tap: port, enable: false)
        MouseLockManager.shared.unlockMouse()
    }

    /// Resumes keyboard and mouse interception after being paused.
    public func resume() {
        guard isIntercepting, let port = machPort else { return }
        CGEvent.tapEnable(tap: port, enable: true)
        MouseLockManager.shared.lockMouse()
    }

    /// Permanently stops the event tap and cleans up all Mach port, run loop, and mouse resources.
    public func stop() {
        guard isIntercepting else { return }

        if let port = machPort {
            CGEvent.tapEnable(tap: port, enable: false)
            CFMachPortInvalidate(port)
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }

        self.machPort = nil
        self.runLoopSource = nil
        self.isIntercepting = false

        // Guaranteed restoration of mouse control
        MouseLockManager.shared.unlockMouse()
    }

    /// Re-enables the event tap if disabled by macOS timeout
    fileprivate func reenableIfNeeded() {
        guard let port = machPort else { return }
        CGEvent.tapEnable(tap: port, enable: true)
    }

    deinit {
        stop()
    }
}

/// C-style event tap callback required by CoreGraphics
private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else {
        return Unmanaged.passUnretained(event)
    }

    let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()

    // Handle system timeout / user-input disablement
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        manager.reenableIfNeeded()
        return Unmanaged.passUnretained(event)
    }

    // Inspect KeyDown events for the Unlock Chord: Cmd + Option + Ctrl + U
    if type == .keyDown {
        let flags = event.flags
        let isCmd = flags.contains(.maskCommand)
        let isOpt = flags.contains(.maskAlternate)
        let isCtrl = flags.contains(.maskControl)
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        // Keycode 32 (0x20) corresponds to ANSI 'U'
        if isCmd && isOpt && isCtrl && keyCode == 32 {
            DispatchQueue.main.async {
                manager.onUnlockChordDetected?()
            }
            // Drop the chord event so it does not leak to underlying applications
            return nil
        }

        var pressedChar: String? = nil
        if let nsEvent = NSEvent(cgEvent: event),
           let chars = nsEvent.charactersIgnoringModifiers,
           !chars.isEmpty {
            pressedChar = chars
        }

        // Trigger visual feedback on the main thread
        DispatchQueue.main.async {
            manager.onKeystrokeIntercepted?(pressedChar)
        }

        // Drop all standard key downs
        return nil
    }

    // Drop all key up and modifier (flagsChanged) events
    if type == .keyUp || type == .flagsChanged {
        return nil
    }

    // Handle Media Keys (Volume Up/Down, Mute, Play/Pause, Rewind, Fast Forward, Brightness)
    // and special system events (NX_SYSDEFINED = 14, NX_KITDEFINED = 13, NX_APPDEFINED = 15)
    if type.rawValue == 14 || type.rawValue == 13 || type.rawValue == 15 {
        DispatchQueue.main.async {
            manager.onKeystrokeIntercepted?(nil)
        }
        // Completely drop media keys so volume and playback are never triggered
        return nil
    }

    // Handle mouse events: clicks, movements, drags, and scrolling
    switch type {
    case .leftMouseDown, .leftMouseUp,
         .rightMouseDown, .rightMouseUp,
         .otherMouseDown, .otherMouseUp,
         .mouseMoved,
         .leftMouseDragged, .rightMouseDragged, .otherMouseDragged,
         .scrollWheel:
        if manager.isMouseInterceptionEnabled {
            return nil // Intercept & drop
        } else {
            return Unmanaged.passUnretained(event) // Pass through to allow clicking UI
        }

    default:
        return Unmanaged.passUnretained(event)
    }
}

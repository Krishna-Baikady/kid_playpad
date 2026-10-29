import AppKit
import SwiftUI

/// SwiftUI modal view presented 30 seconds before the session timer completes,
/// displaying a live 30-second countdown with buttons to Add Time or Unlock Mac.
public struct TimeoutAlertView: View {
    @ObservedObject var sessionManager = LockSessionManager.shared
    public let onAddTime: () -> Void
    public let onUnlock: () -> Void

    public init(onAddTime: @escaping () -> Void, onUnlock: @escaping () -> Void) {
        self.onAddTime = onAddTime
        self.onUnlock = onUnlock
    }

    public var body: some View {
        VStack(spacing: 22) {
            // Live countdown timer badge
            ZStack {
                Circle()
                    .fill(Color(red: 0.64, green: 0.49, blue: 0.45).opacity(0.18))
                    .frame(width: 76, height: 76)
                    .overlay(
                        Circle()
                            .stroke(Color(red: 0.64, green: 0.49, blue: 0.45).opacity(0.4), lineWidth: 2)
                    )

                VStack(spacing: 0) {
                    Text("\(sessionManager.warningSecondsRemaining)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.75, green: 0.60, blue: 0.50))
                    Text("sec")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(MutedPalette.textSecondary)
                }
            }
            .padding(.top, 4)

            // Titles
            VStack(spacing: 6) {
                Text("Session Ending Soon")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(MutedPalette.textPrimary)

                Text("The keyboard lock session will finish in \(sessionManager.warningSecondsRemaining) seconds.\nClick 'Add Time' to extend, or 'Unlock Mac' to end now.")
                    .font(.system(size: 13))
                    .foregroundColor(MutedPalette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            // Action buttons (Mouse is unlocked so these are easily clickable)
            HStack(spacing: 16) {
                // Unlock / Quit button
                Button(action: onUnlock) {
                    HStack {
                        Image(systemName: "lock.open.fill")
                        Text("Unlock Mac")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .frame(minWidth: 140, minHeight: 40)
                    .background(Color(white: 0.28))
                    .foregroundColor(MutedPalette.textPrimary)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                // Add Time button
                Button(action: onAddTime) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Time")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .frame(minWidth: 150, minHeight: 40)
                    .background(Color(red: 0.47, green: 0.53, blue: 0.59))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 6)
        }
        .padding(26)
        .frame(width: 440)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(MutedPalette.dialogBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(MutedPalette.mutedBorder, lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.4), radius: 28, x: 0, y: 14)
    }
}

/// Window controller for presenting the 30-second warning timeout alert
public final class TimeoutAlertWindowController {
    public static let shared = TimeoutAlertWindowController()

    private var alertWindow: NSWindow?

    private init() {}

    public func showAlert(onAddTime: @escaping () -> Void, onUnlock: @escaping () -> Void) {
        closeAlert()

        let contentView = TimeoutAlertView(
            onAddTime: { [weak self] in
                self?.closeAlert()
                onAddTime()
            },
            onUnlock: { [weak self] in
                self?.closeAlert()
                onUnlock()
            }
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 290),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.center()
        // Position window above the transparent screen saver overlay so it receives clicks cleanly
        window.level = .screenSaver + 1
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.alertWindow = window
    }

    public func closeAlert() {
        alertWindow?.orderOut(nil)
        alertWindow = nil
    }
}

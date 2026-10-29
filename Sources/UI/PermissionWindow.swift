import AppKit
import SwiftUI

/// Permission prompt view explaining Accessibility requirements and guiding the user to System Settings
public struct PermissionPromptView: View {
    public let onAuthorized: () -> Void
    public let onQuit: () -> Void

    @State private var statusMessage: String? = nil
    @State private var isSuccessStatus: Bool = false

    public init(onAuthorized: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.onAuthorized = onAuthorized
        self.onQuit = onQuit
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(red: 0.47, green: 0.53, blue: 0.59).opacity(0.18))
                    .frame(width: 56, height: 56)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(red: 0.54, green: 0.60, blue: 0.52))
            }
            .padding(.top, 4)

            // Description
            VStack(spacing: 6) {
                Text("Accessibility Access Required")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(MutedPalette.textPrimary)

                Text("Kid PlayPad requires macOS Accessibility authorization to intercept keyboard and mouse inputs, keeping your Mac safe while your child plays.")
                    .font(.system(size: 13))
                    .foregroundColor(MutedPalette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Normal Setup Steps Box
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    Text("1")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Color(red: 0.54, green: 0.60, blue: 0.52))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Click 'Open Settings' below.")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(MutedPalette.textPrimary)
                        Text("Opens System Settings → Privacy & Security → Accessibility.")
                            .font(.system(size: 11))
                            .foregroundColor(MutedPalette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(alignment: .top, spacing: 10) {
                    Text("2")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Color(red: 0.54, green: 0.60, blue: 0.52))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Turn ON the toggle for \(AccessibilityHelper.targetDisplayName).")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(MutedPalette.textPrimary)
                        if !AccessibilityHelper.isRunningAsAppBundle {
                            Text("Note: If launched from Terminal, enable 'Terminal'. If launched as an app, enable 'Kid PlayPad'.")
                                .font(.system(size: 11))
                                .foregroundColor(MutedPalette.textSecondary.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                HStack(alignment: .top, spacing: 10) {
                    Text("3")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Color(red: 0.54, green: 0.60, blue: 0.52))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Return here and click 'Check permission and START'.")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(MutedPalette.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("The app will engage full input protection and begin your session.")
                            .font(.system(size: 11))
                            .foregroundColor(MutedPalette.textSecondary)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MutedPalette.dialogCard)
            .cornerRadius(10)

            // Troubleshooting Card: If Toggle is Already ON
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color(red: 0.90, green: 0.72, blue: 0.45))
                    Text("If the toggle is ALREADY ON but the app won't start:")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.92, green: 0.78, blue: 0.55))
                }

                Text("macOS keeps an outdated security cache when apps are rebuilt, showing the toggle 'ON' even though authorization has expired.")
                    .font(.system(size: 11))
                    .foregroundColor(MutedPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 6) {
                        Text("•").fontWeight(.bold).foregroundColor(MutedPalette.textSecondary)
                        Text("Quick Fix: Click the 'Reset Cache' button below. Then turn the toggle back ON in System Settings and click 'Check permission and START'.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(MutedPalette.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(alignment: .top, spacing: 6) {
                        Text("•").fontWeight(.bold).foregroundColor(MutedPalette.textSecondary)
                        Text("Manual Fix: In System Settings, select Kid PlayPad, click the minus [ — ] button at the bottom of the list to remove it, and turn it back ON.")
                            .font(.system(size: 11))
                            .foregroundColor(MutedPalette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.22, green: 0.21, blue: 0.19))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(red: 0.55, green: 0.45, blue: 0.30), lineWidth: 1)
            )
            .cornerRadius(10)

            // Status feedback banner
            if let status = statusMessage {
                HStack(spacing: 8) {
                    Image(systemName: isSuccessStatus ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(isSuccessStatus ? Color(red: 0.6, green: 0.85, blue: 0.6) : Color(red: 0.95, green: 0.6, blue: 0.5))
                    Text(status)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(isSuccessStatus ? Color(red: 0.8, green: 0.95, blue: 0.8) : Color(red: 0.98, green: 0.85, blue: 0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isSuccessStatus ? Color(red: 0.25, green: 0.45, blue: 0.25, opacity: 0.35) : Color(red: 0.55, green: 0.25, blue: 0.2, opacity: 0.35))
                .cornerRadius(8)
            }

            // Buttons
            HStack(spacing: 10) {
                Button(action: onQuit) {
                    Text("Quit")
                        .font(.system(size: 13, weight: .medium))
                        .frame(minWidth: 60, minHeight: 36)
                        .background(Color(white: 0.28))
                        .foregroundColor(MutedPalette.textPrimary)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button(action: {
                    AccessibilityHelper.resetTCC()
                    AccessibilityHelper.requestAccessibilityPermission()
                    AccessibilityHelper.openSystemSettingsAccessibility()
                    statusMessage = "Cache cleared & re-registered! Turn the toggle ON in System Settings, then click 'Check permission and START'."
                    isSuccessStatus = true
                }) {
                    Text("Reset Cache")
                        .font(.system(size: 13, weight: .medium))
                        .frame(minWidth: 95, minHeight: 36)
                        .background(Color(white: 0.32))
                        .foregroundColor(MutedPalette.textPrimary)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button(action: {
                    AccessibilityHelper.openSystemSettingsAccessibility()
                }) {
                    Text("Open Settings")
                        .font(.system(size: 13, weight: .medium))
                        .frame(minWidth: 105, minHeight: 36)
                        .background(Color(white: 0.35))
                        .foregroundColor(MutedPalette.textPrimary)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button(action: {
                    if AccessibilityHelper.isProcessTrusted() {
                        onAuthorized()
                    } else {
                        AccessibilityHelper.requestAccessibilityPermission()
                        statusMessage = "Permission not detected yet. If the toggle is already ON, please click 'Reset Cache' or remove Kid PlayPad with the [ — ] button in System Settings."
                        isSuccessStatus = false
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.circle.fill")
                        Text("Check permission and START")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .frame(minWidth: 215, minHeight: 36)
                    .background(Color(red: 0.44, green: 0.55, blue: 0.42))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(width: 580)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(MutedPalette.dialogBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(MutedPalette.mutedBorder, lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.35), radius: 24, x: 0, y: 12)
    }
}

/// Window controller for presenting the accessibility permission prompt
public final class PermissionWindowController {
    public static let shared = PermissionWindowController()

    private var window: NSWindow?

    private init() {}

    public func showPrompt(onAuthorized: @escaping () -> Void, onQuit: @escaping () -> Void) {
        closePrompt()

        let contentView = PermissionPromptView(
            onAuthorized: { [weak self] in
                self?.closePrompt()
                onAuthorized()
            },
            onQuit: { [weak self] in
                self?.closePrompt()
                onQuit()
            }
        )

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 570),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        win.title = "Kid PlayPad — Accessibility Authorization"
        win.center()
        win.level = .floating
        win.backgroundColor = NSColor(MutedPalette.dialogBackground)
        win.contentView = NSHostingView(rootView: contentView)
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = win
    }

    public func closePrompt() {
        window?.orderOut(nil)
        window = nil
    }
}


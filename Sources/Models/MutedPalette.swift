import SwiftUI

/// Curated non-vibrant color palette consisting strictly of dull pastels,
/// desaturated earth tones, and warm grays to avoid sensory overstimulation.
public struct MutedPalette {
    public static let colors: [Color] = [
        Color(red: 0.54, green: 0.60, blue: 0.52), // Muted Sage
        Color(red: 0.47, green: 0.53, blue: 0.59), // Dull Slate
        Color(red: 0.64, green: 0.49, blue: 0.45), // Dusty Clay
        Color(red: 0.62, green: 0.58, blue: 0.51), // Muted Sand / Taupe
        Color(red: 0.56, green: 0.56, blue: 0.58), // Soft Pebble Gray
        Color(red: 0.43, green: 0.48, blue: 0.41), // Dull Moss
        Color(red: 0.56, green: 0.51, blue: 0.58), // Muted Dusty Lavender
        Color(red: 0.67, green: 0.64, blue: 0.56), // Soft Warm Wheat
        Color(red: 0.41, green: 0.48, blue: 0.55), // Dull Slate Blue
        Color(red: 0.58, green: 0.53, blue: 0.48)  // Desaturated Warm Stone
    ]

    /// Returns a random muted color from the curated non-vibrant palette.
    public static func randomColor() -> Color {
        colors.randomElement() ?? Color(red: 0.5, green: 0.5, blue: 0.5)
    }

    /// Background tint for modals and dialogs
    public static let dialogBackground = Color(red: 0.18, green: 0.19, blue: 0.20, opacity: 0.95)
    public static let dialogCard = Color(red: 0.24, green: 0.25, blue: 0.26)
    public static let mutedBorder = Color(red: 0.35, green: 0.36, blue: 0.38)
    public static let textPrimary = Color(red: 0.88, green: 0.88, blue: 0.88)
    public static let textSecondary = Color(red: 0.68, green: 0.68, blue: 0.70)
}

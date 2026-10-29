import SwiftUI

/// Represents the geometric shape variants used in Phase 1
public enum ShapeKind: CaseIterable {
    case circle
    case roundedRectangle
    case softTriangle
    case oval
    case softDiamond
}

/// The visual element spawned in response to intercepted keystrokes
public enum VisualContent {
    case alphabet(character: String)
    case shape(kind: ShapeKind)
    case handWave
}

/// An individual animated visual item rendered on the transparent overlay
public struct VisualItem: Identifiable {
    public let id = UUID()
    public let content: VisualContent
    public let color: Color
    public let position: CGPoint
    public let size: CGFloat
    public let createdAt: Date
    public var isExpiring: Bool = false

    public init(
        content: VisualContent,
        color: Color,
        position: CGPoint,
        size: CGFloat = 110,
        createdAt: Date = Date()
    ) {
        self.content = content
        self.color = color
        self.position = position
        self.size = size
        self.createdAt = createdAt
    }
}

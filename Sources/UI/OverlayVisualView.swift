import SwiftUI

/// Custom shape for soft triangle
struct SoftTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let top = CGPoint(x: rect.midX, y: rect.minY + 5)
        let bottomLeft = CGPoint(x: rect.minX + 5, y: rect.maxY - 5)
        let bottomRight = CGPoint(x: rect.maxX - 5, y: rect.maxY - 5)

        path.move(to: top)
        path.addLine(to: bottomRight)
        path.addLine(to: bottomLeft)
        path.closeSubpath()
        return path
    }
}

/// Custom shape for soft diamond
struct SoftDiamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

/// Fullscreen transparent SwiftUI overlay rendering Phase 1 (letters & shapes)
/// and Phase 2 (continuous moving hand waving goodbye mascot) visuals.
public struct OverlayVisualView: View {
    @ObservedObject var sessionManager = LockSessionManager.shared

    public init() {}

    public var body: some View {
        ZStack {
            // Completely transparent background
            Color.clear
                .ignoresSafeArea()

            // Top-left discrete countdown minute counter (e.g. counts down: 2, then 1)
            VStack {
                HStack {
                    Text("\(sessionManager.countdownMinutes)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(MutedPalette.textSecondary.opacity(0.85))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color(white: 0.18, opacity: 0.65))
                                .overlay(
                                    Circle()
                                        .stroke(MutedPalette.mutedBorder.opacity(0.4), lineWidth: 1)
                                )
                        )
                        .padding(.top, 24)
                        .padding(.leading, 24)
                    Spacer()
                }
                Spacer()
            }

            // Phase 2: Continuous moving hand-waving goodbye mascot throughout the second minute
            if sessionManager.currentPhase == .phase2 {
                MovingHandWaveMascotView()
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            }

            // Active visual elements spawned by key presses
            ForEach(sessionManager.activeVisuals) { item in
                ItemRenderer(item: item)
                    .position(item.position)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.6).combined(with: .opacity),
                        removal: .scale(scale: 1.1).combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: sessionManager.activeVisuals.count)
        .animation(.easeInOut(duration: 0.5), value: sessionManager.currentPhase)
    }
}

/// Continuously moving, animated waving hand mascot for Phase 2 (goodbye phase)
private struct MovingHandWaveMascotView: View {
    @State private var isWaving: Bool = false
    @State private var floatY: CGFloat = -14
    @State private var floatX: CGFloat = -18

    var body: some View {
        VStack(spacing: 16) {
            Text("👋")
                .font(.system(size: 110))
                .rotationEffect(.degrees(isWaving ? 20 : -20), anchor: .bottomTrailing)
                .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 6)

            Text("Time to say goodbye 👋")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(MutedPalette.textPrimary)
                .padding(.horizontal, 22)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(white: 0.16, opacity: 0.85))
                        .overlay(
                            Capsule()
                                .stroke(MutedPalette.mutedBorder.opacity(0.6), lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .offset(x: floatX, y: floatY)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                isWaving = true
            }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                floatY = 14
            }
            withAnimation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true)) {
                floatX = 18
            }
        }
    }
}

/// Renders a single VisualItem according to its content variant
private struct ItemRenderer: View {
    let item: VisualItem

    var body: some View {
        switch item.content {
        case .alphabet(let character):
            ZStack {
                Circle()
                    .fill(item.color.opacity(0.18))
                    .frame(width: item.size, height: item.size)
                    .overlay(
                        Circle().stroke(item.color.opacity(0.4), lineWidth: 3)
                    )

                Text(character)
                    .font(.system(size: item.size * 0.55, weight: .bold, design: .rounded))
                    .foregroundColor(item.color)
            }

        case .shape(let kind):
            Group {
                switch kind {
                case .circle:
                    Circle().fill(item.color.opacity(0.85)).frame(width: item.size, height: item.size)
                case .roundedRectangle:
                    RoundedRectangle(cornerRadius: 24, style: .continuous).fill(item.color.opacity(0.85)).frame(width: item.size, height: item.size)
                case .softTriangle:
                    SoftTriangle().fill(item.color.opacity(0.85)).frame(width: item.size, height: item.size)
                case .oval:
                    Ellipse().fill(item.color.opacity(0.85)).frame(width: item.size * 1.25, height: item.size * 0.85)
                case .softDiamond:
                    SoftDiamond().fill(item.color.opacity(0.85)).frame(width: item.size, height: item.size)
                }
            }
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)

        case .handWave:
            VStack(spacing: 8) {
                Text("👋")
                    .font(.system(size: item.size * 0.75))
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)

                Text("Bye-bye!")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(item.color)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(Color(white: 0.15, opacity: 0.75))
                    )
            }
        }
    }
}

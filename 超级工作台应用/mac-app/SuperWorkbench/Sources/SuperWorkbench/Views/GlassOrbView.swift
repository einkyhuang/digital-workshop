import SwiftUI

/// Translucent iridescent glass orb — FAB / AI avatar / panel header.
/// Blue-lavender glass body, saturated rainbow rim, vertical bright-blue refraction; animated.
struct GlassOrbView: View {
    var size: CGFloat = 48
    var isActive: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovering = false

    // Brand iridescence
    private static let blue = Color(red: 0x4A / 255.0, green: 0x7B / 255.0, blue: 0xFF / 255.0)
    private static let violet = Color(red: 0x9B / 255.0, green: 0x7B / 255.0, blue: 0xFF / 255.0)
    private static let cyan = Color(red: 0.25, green: 0.85, blue: 0.95)
    private static let pink = Color(red: 1.0, green: 0.45, blue: 0.72)
    private static let edge = Color(red: 0.35, green: 0.42, blue: 0.55)

    private var breathScale: CGFloat {
        if reduceMotion { return hovering ? 1.06 : 1.0 }
        return hovering ? 1.08 : 1.0
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1.0 : 1.0 / 30.0, paused: reduceMotion && !isActive)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let rimPeriod = isActive ? 3.2 : 8.0
            let streakPeriod = isActive ? 2.4 : 6.0
            let rimAngle = reduceMotion
                ? Angle.degrees(0)
                : Angle.degrees((t.truncatingRemainder(dividingBy: rimPeriod) / rimPeriod) * 360)
            // Keep the vertical refraction band mostly upright; slight sway when animated.
            let bandSway: Double = reduceMotion ? 0 : sin(t * (isActive ? 1.8 : 0.9)) * 8
            let streakSpin = reduceMotion
                ? Angle.degrees(0)
                : Angle.degrees((t.truncatingRemainder(dividingBy: streakPeriod) / streakPeriod) * 360)
            let breath: CGFloat = {
                guard !reduceMotion else { return 1.0 }
                let period = isActive ? 1.6 : 3.2
                let phase = (t.truncatingRemainder(dividingBy: period) / period) * .pi * 2
                let amp: CGFloat = isActive ? 0.05 : 0.04
                return 1.0 + CGFloat(sin(phase)) * amp
            }()

            ZStack {
                // Stronger blue-tinted drop shadow (~0.25)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Self.blue.opacity(isActive ? 0.38 : 0.28),
                                Color(red: 0.25, green: 0.35, blue: 0.55).opacity(0.18),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: size * 0.1,
                            endRadius: size * 0.7
                        )
                    )
                    .frame(width: size * 1.28, height: size * 1.28)
                    .offset(y: size * 0.08)
                    .blur(radius: size * 0.12)

                // Body — light blue → lavender (not near-white)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.88, green: 0.93, blue: 1.0).opacity(0.98),
                                Color(red: 0.72, green: 0.82, blue: 0.98).opacity(0.88),
                                Color(red: 0.78, green: 0.72, blue: 0.96).opacity(0.72),
                                Color(red: 0.55, green: 0.68, blue: 0.92).opacity(0.55)
                            ],
                            center: UnitPoint(x: 0.34, y: 0.30),
                            startRadius: 0,
                            endRadius: size * 0.58
                        )
                    )
                    .frame(width: size, height: size)
                    .overlay {
                        // Thin darker blue-grey edge so it reads on light backgrounds
                        Circle()
                            .strokeBorder(Self.edge.opacity(0.55), lineWidth: max(1.0, size * 0.028))
                    }
                    .background {
                        Circle()
                            .fill(Self.blue.opacity(0.18))
                            .blur(radius: size * 0.14)
                    }

                // Wide saturated iridescent rim
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Self.blue.opacity(1.0),
                                Self.cyan.opacity(0.98),
                                Self.violet.opacity(1.0),
                                Self.pink.opacity(0.95),
                                Self.blue.opacity(1.0)
                            ]),
                            center: .center,
                            angle: rimAngle
                        ),
                        lineWidth: max(2.8, size * 0.09)
                    )
                    .frame(width: size * 0.98, height: size * 0.98)
                    .blur(radius: size * 0.02)
                    .opacity(isActive ? 1.0 : 0.95)
                    .blendMode(.plusLighter)

                // Outer soft glow of the rim
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Self.cyan.opacity(0.7),
                                Self.pink.opacity(0.65),
                                Self.violet.opacity(0.7),
                                Self.blue.opacity(0.75),
                                Self.cyan.opacity(0.7)
                            ]),
                            center: .center,
                            angle: Angle.degrees(-rimAngle.degrees)
                        ),
                        lineWidth: max(3.5, size * 0.12)
                    )
                    .frame(width: size * 1.06, height: size * 1.06)
                    .blur(radius: size * 0.07)
                    .opacity(isActive ? 0.95 : 0.75)

                // Prominent vertical curved bright-blue refraction band (slightly right of center)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.0),
                                Self.cyan.opacity(0.55),
                                Self.blue.opacity(0.95),
                                Color(red: 0.15, green: 0.35, blue: 0.95).opacity(0.9),
                                Self.violet.opacity(0.45),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: max(3.0, size * 0.11), height: size * 0.78)
                    .offset(x: size * 0.14)
                    .rotationEffect(.degrees(bandSway - 4))
                    .blur(radius: size * 0.018)
                    .opacity(0.95)
                    .blendMode(.plusLighter)

                // Soft twin of the band (glass thickness)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.55),
                                Self.blue.opacity(0.35),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: max(1.5, size * 0.045), height: size * 0.62)
                    .offset(x: size * 0.10)
                    .rotationEffect(.degrees(bandSway - 2))
                    .blur(radius: size * 0.01)

                // Inner moving highlight arc (secondary iridescence)
                Circle()
                    .trim(from: 0.05, to: 0.38)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.95),
                                Self.cyan.opacity(0.85),
                                Self.pink.opacity(0.55),
                                Color.white.opacity(0.0)
                            ]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: max(1.6, size * 0.05), lineCap: .round)
                    )
                    .frame(width: size * 0.70, height: size * 0.70)
                    .rotationEffect(streakSpin)
                    .blur(radius: size * 0.012)
                    .opacity(0.9)

                // Crisp white specular at top-left
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(1.0), Color.white.opacity(0.55), Color.white.opacity(0.0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.22
                        )
                    )
                    .frame(width: size * 0.36, height: size * 0.20)
                    .offset(x: -size * 0.16, y: -size * 0.20)
                    .blur(radius: size * 0.008)
                    .opacity(0.98)

                if isActive {
                    Circle()
                        .stroke(Self.cyan.opacity(0.65), lineWidth: 1.2)
                        .frame(width: size * 1.22, height: size * 1.22)
                        .blur(radius: size * 0.05)
                        .opacity(0.65 + 0.35 * Double(sin(t * 4)))
                }
            }
            .frame(width: size * 1.3, height: size * 1.3)
            .scaleEffect(breath * breathScale)
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .onHover { hovering = $0 }
        .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview("GlassOrb") {
    HStack(spacing: 24) {
        GlassOrbView(size: 28, isActive: false)
        GlassOrbView(size: 48, isActive: false)
        GlassOrbView(size: 56, isActive: true)
    }
    .padding(40)
    .background(Color(white: 0.92))
}
#endif

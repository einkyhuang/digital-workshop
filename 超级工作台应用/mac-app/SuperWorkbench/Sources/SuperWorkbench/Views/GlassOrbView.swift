import SwiftUI

/// Translucent iridescent glass orb — FAB / AI avatar / panel header.
/// Pale near-white body, rainbow refraction rim, curved light streak; animated.
struct GlassOrbView: View {
    var size: CGFloat = 48
    var isActive: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovering = false

    private var breathScale: CGFloat {
        if reduceMotion { return hovering ? 1.06 : 1.0 }
        return hovering ? 1.08 : 1.0
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1.0 : 1.0 / 30.0, paused: reduceMotion && !isActive)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let rimPeriod = isActive ? 3.2 : 8.0
            let streakPeriod = isActive ? 2.4 : 6.0
            let rimAngle = reduceMotion ? Angle.degrees(0) : Angle.degrees((t.truncatingRemainder(dividingBy: rimPeriod) / rimPeriod) * 360)
            let streakAngle = reduceMotion ? Angle.degrees(25) : Angle.degrees((t.truncatingRemainder(dividingBy: streakPeriod) / streakPeriod) * 360)
            let breath: CGFloat = {
                guard !reduceMotion else { return 1.0 }
                let period = isActive ? 1.6 : 3.2
                let phase = (t.truncatingRemainder(dividingBy: period) / period) * .pi * 2
                let amp: CGFloat = isActive ? 0.05 : 0.04
                return 1.0 + CGFloat(sin(phase)) * amp
            }()

            ZStack {
                // Soft ambient drop shadow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.black.opacity(isActive ? 0.22 : 0.14),
                                Color.black.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: size * 0.15,
                            endRadius: size * 0.62
                        )
                    )
                    .frame(width: size * 1.15, height: size * 1.15)
                    .offset(y: size * 0.06)
                    .blur(radius: size * 0.08)

                // Core glass body — white → clear
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.95),
                                Color.white.opacity(0.55),
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.05)
                            ],
                            center: UnitPoint(x: 0.35, y: 0.28),
                            startRadius: 0,
                            endRadius: size * 0.55
                        )
                    )
                    .frame(width: size, height: size)
                    .overlay {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.55), lineWidth: max(0.8, size * 0.02))
                    }
                    .background {
                        Circle()
                            .fill(Color.white.opacity(0.25))
                            .blur(radius: size * 0.12)
                    }

                // Iridescent rim (angular gradient), blurred + rotating
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.55, green: 0.75, blue: 1.0).opacity(0.95),
                                Color(red: 0.75, green: 0.55, blue: 1.0).opacity(0.9),
                                Color(red: 1.0, green: 0.55, blue: 0.75).opacity(0.9),
                                Color(red: 0.45, green: 0.95, blue: 0.95).opacity(0.95),
                                Color(red: 0.55, green: 0.75, blue: 1.0).opacity(0.95)
                            ]),
                            center: .center,
                            angle: rimAngle
                        ),
                        lineWidth: max(1.5, size * 0.055)
                    )
                    .frame(width: size * 0.96, height: size * 0.96)
                    .blur(radius: size * 0.035)
                    .opacity(isActive ? 1.0 : 0.85)
                    .blendMode(.plusLighter)

                // Soft secondary rim glow
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color.cyan.opacity(0.35),
                                Color.pink.opacity(0.3),
                                Color.purple.opacity(0.28),
                                Color.blue.opacity(0.35),
                                Color.cyan.opacity(0.35)
                            ]),
                            center: .center,
                            angle: Angle.degrees(-rimAngle.degrees)
                        ),
                        lineWidth: max(2.0, size * 0.08)
                    )
                    .frame(width: size * 1.02, height: size * 1.02)
                    .blur(radius: size * 0.08)
                    .opacity(isActive ? 0.9 : 0.55)

                // Curved light streak (inner highlight arc)
                Circle()
                    .trim(from: 0.08, to: 0.42)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.95),
                                Color(red: 0.6, green: 0.85, blue: 1.0).opacity(0.85),
                                Color(red: 1.0, green: 0.7, blue: 0.9).opacity(0.55),
                                Color.white.opacity(0.0)
                            ]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: max(1.2, size * 0.045), lineCap: .round)
                    )
                    .frame(width: size * 0.72, height: size * 0.72)
                    .rotationEffect(streakAngle)
                    .blur(radius: size * 0.015)
                    .opacity(0.95)

                // Specular pearl highlight (top-left)
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.9), Color.white.opacity(0.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size * 0.38, height: size * 0.22)
                    .offset(x: -size * 0.14, y: -size * 0.18)
                    .blur(radius: size * 0.02)
                    .opacity(0.85)

                // Active glow pulse
                if isActive {
                    Circle()
                        .stroke(Color.cyan.opacity(0.45), lineWidth: 1)
                        .frame(width: size * 1.18, height: size * 1.18)
                        .blur(radius: size * 0.06)
                        .opacity(0.7 + 0.3 * Double(sin(t * 4)))
                }
            }
            .frame(width: size * 1.25, height: size * 1.25)
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

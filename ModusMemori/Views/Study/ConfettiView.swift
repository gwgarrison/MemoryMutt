import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    private let colors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink, .mint, .cyan
    ]
    
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    
                    for particle in particles {
                        let elapsed = now - particle.startTime
                        guard elapsed >= 0 && elapsed < particle.lifetime else { continue }
                        
                        let progress = elapsed / particle.lifetime
                        
                        // Position: fall down with gravity + horizontal wobble
                        let x = particle.startX + particle.velocityX * elapsed + particle.wobbleAmplitude * sin(elapsed * particle.wobbleFrequency)
                        let y = particle.startY + particle.velocityY * elapsed + 0.5 * 500 * elapsed * elapsed
                        
                        // Fade out in last 30%
                        let opacity = progress > 0.7 ? 1.0 - ((progress - 0.7) / 0.3) : 1.0
                        
                        // Rotation
                        let angle = Angle.degrees(particle.rotationSpeed * elapsed * 360)
                        
                        // Scale shrinks slightly
                        let scale = 1.0 - progress * 0.3
                        
                        guard y < size.height + 100 else { continue }
                        
                        var ctx = context
                        ctx.translateBy(x: x, y: y)
                        ctx.rotate(by: angle)
                        ctx.scaleBy(x: scale, y: scale)
                        ctx.opacity = opacity
                        
                        let rect = CGRect(x: -particle.width / 2, y: -particle.height / 2, width: particle.width, height: particle.height)
                        let path: Path
                        
                        switch particle.shape {
                        case 0:
                            path = Path(ellipseIn: rect)
                        case 1:
                            path = Path(rect)
                        default:
                            var p = Path()
                            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
                            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                            p.closeSubpath()
                            path = p
                        }
                        
                        ctx.fill(path, with: .color(particle.color))
                    }
                }
            }
            .onAppear {
                spawnBurst(in: geo.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func spawnBurst(in size: CGSize) {
        let now = Date().timeIntervalSinceReferenceDate
        var newParticles: [ConfettiParticle] = []
        
        let w = size.width
        
        for _ in 0..<100 {
            let delay = Double.random(in: 0...0.5)
            let spawnX = Double.random(in: 0...w)
            let spawnY = Double.random(in: -30...0)
            
            let particle = ConfettiParticle(
                startTime: now + delay,
                lifetime: Double.random(in: 2.0...3.5),
                startX: spawnX,
                startY: spawnY,
                velocityX: Double.random(in: -100...100),
                velocityY: Double.random(in: 40...200),
                rotationSpeed: Double.random(in: -2...2),
                wobbleAmplitude: Double.random(in: 15...40),
                wobbleFrequency: Double.random(in: 3...7),
                width: Double.random(in: 8...16),
                height: Double.random(in: 4...12),
                color: colors.randomElement() ?? .yellow,
                shape: Int.random(in: 0...2)
            )
            newParticles.append(particle)
        }
        
        particles = newParticles
    }
}

private struct ConfettiParticle {
    let startTime: TimeInterval
    let lifetime: TimeInterval
    let startX: Double
    let startY: Double
    let velocityX: Double
    let velocityY: Double
    let rotationSpeed: Double
    let wobbleAmplitude: Double
    let wobbleFrequency: Double
    let width: Double
    let height: Double
    let color: Color
    let shape: Int // 0=circle, 1=rect, 2=triangle
}

#Preview {
    ZStack {
        Color.black.opacity(0.2)
        ConfettiView()
    }
}

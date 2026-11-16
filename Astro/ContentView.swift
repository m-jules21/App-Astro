import SwiftUI

private struct Meteor: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var speed: CGFloat
}

struct ContentView: View {
    @State private var shipX: CGFloat = 0.5
    @State private var meteors: [Meteor] = []
    @State private var score = 0
    @State private var bestScore = UserDefaults.standard.integer(forKey: "astro.bestScore")
    @State private var isPlaying = false
    @State private var hasStarted = false
    @State private var lastSpawn = Date()
    @State private var lastTick = Date()
    @State private var gameStartedAt = Date()

    private let tick = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(red: 0.025, green: 0.035, blue: 0.12).ignoresSafeArea()

                Canvas { context, size in
                    drawStars(in: &context, size: size)
                    for meteor in meteors {
                        let rect = CGRect(x: meteor.x * size.width, y: meteor.y * size.height,
                                          width: meteor.size, height: meteor.size * 1.35)
                        let path = Path(roundedRect: rect, cornerRadius: meteor.size / 2)
                        context.fill(path, with: .color(Color(red: 1, green: 0.39, blue: 0.23)))
                        context.addFilter(.shadow(color: .orange.opacity(0.6), radius: 8))
                        context.fill(path, with: .color(.orange.opacity(0.22)))
                    }
                }
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ASTRO").font(.system(size: 13, weight: .black, design: .rounded)).tracking(3).foregroundStyle(.cyan)
                            Text("RECORD  \(bestScore)").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.55))
                        }
                        Spacer()
                        Text("\(score)").font(.system(size: 34, weight: .black, design: .rounded)).monospacedDigit().foregroundStyle(.white)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 14)

                    Spacer()

                    Canvas { context, size in
                        let x = shipX * size.width
                        let y = size.height * 0.80
                        var ship = Path()
                        ship.move(to: CGPoint(x: x, y: y - 28))
                        ship.addLine(to: CGPoint(x: x - 22, y: y + 20))
                        ship.addQuadCurve(to: CGPoint(x: x + 22, y: y + 20), control: CGPoint(x: x, y: y + 10))
                        ship.closeSubpath()
                        context.addFilter(.shadow(color: .cyan.opacity(0.9), radius: 14))
                        context.fill(ship, with: .color(Color(red: 0.25, green: 0.88, blue: 1)))
                        let flame = Path(roundedRect: CGRect(x: x - 5, y: y + 18, width: 10, height: 17), cornerRadius: 5)
                        context.fill(flame, with: .color(.orange))
                    }
                    .frame(height: 90)
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                        guard isPlaying else { return }
                        shipX = min(max(value.location.x / max(geometry.size.width, 1), 0.07), 0.93)
                    })

                    Text(isPlaying ? "GLISSE TON DOIGT POUR ESQUIVER" : "")
                        .font(.system(size: 11, weight: .bold, design: .rounded)).tracking(1.5)
                        .foregroundStyle(.white.opacity(0.35)).padding(.bottom, 18)
                }

                if !isPlaying {
                    VStack(spacing: 14) {
                        Text(hasStarted ? "OUPS !" : "PRÊT À DÉCOLLER ?")
                            .font(.system(size: 27, weight: .black, design: .rounded)).foregroundStyle(.white)
                        Text(hasStarted ? "Score : \(score)" : "Évite les météorites le plus longtemps possible.")
                            .font(.system(size: 15, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.7))
                        Button(action: startGame) {
                            Text(hasStarted ? "REJOUER" : "JOUER")
                                .font(.system(size: 16, weight: .black, design: .rounded)).tracking(2)
                                .foregroundStyle(Color(red: 0.02, green: 0.06, blue: 0.14))
                                .padding(.horizontal, 38).padding(.vertical, 15)
                                .background(Capsule().fill(Color.cyan))
                        }
                        .padding(.top, 6)
                    }
                    .padding(30)
                    .background(RoundedRectangle(cornerRadius: 26).fill(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 26).stroke(.white.opacity(0.12))))
                    .padding(.horizontal, 28)
                }
            }
            .onReceive(tick) { now in
                guard isPlaying else { lastTick = now; return }
                let dt = min(now.timeIntervalSince(lastTick), 0.06)
                lastTick = now
                updateGame(dt: CGFloat(dt), now: now, size: geometry.size)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func drawStars(in context: inout GraphicsContext, size: CGSize) {
        for index in 0..<70 {
            let x = CGFloat((index * 73 + 19) % 997) / 997 * size.width
            let y = CGFloat((index * 137 + 41) % 991) / 991 * size.height
            let dot = CGRect(x: x, y: y, width: index.isMultiple(of: 7) ? 2 : 1, height: index.isMultiple(of: 7) ? 2 : 1)
            context.fill(Path(ellipseIn: dot), with: .color(.white.opacity(index.isMultiple(of: 3) ? 0.55 : 0.22)))
        }
    }

    private func startGame() {
        meteors = []
        score = 0
        shipX = 0.5
        lastSpawn = Date()
        lastTick = Date()
        gameStartedAt = Date()
        hasStarted = true
        isPlaying = true
    }

    private func updateGame(dt: CGFloat, now: Date, size: CGSize) {
        score = Int(now.timeIntervalSince(gameStartedAt) * 10)
        if now.timeIntervalSince(lastSpawn) > max(0.32, 0.95 - Double(score) / 240) {
            meteors.append(Meteor(x: CGFloat.random(in: 0.06...0.94), y: -0.08,
                                  size: CGFloat.random(in: 23...36), speed: CGFloat.random(in: 0.34...0.55) + CGFloat(score) / 700))
            lastSpawn = now
        }

        for index in meteors.indices {
            meteors[index].y += meteors[index].speed * dt
        }
        meteors.removeAll { $0.y > 1.1 }

        let shipCenter = CGPoint(x: shipX * size.width, y: size.height * 0.80)
        let shipBox = CGRect(x: shipCenter.x - 15, y: shipCenter.y - 18, width: 30, height: 34)
        let hit = meteors.contains { meteor in
            let rect = CGRect(x: meteor.x * size.width, y: meteor.y * size.height,
                              width: meteor.size, height: meteor.size * 1.35)
            return shipBox.intersects(rect.insetBy(dx: 5, dy: 5))
        }
        if hit {
            isPlaying = false
            if score > bestScore {
                bestScore = score
                UserDefaults.standard.set(bestScore, forKey: "astro.bestScore")
            }
        }
    }
}

import SwiftUI
import SpriteKit

struct ContentView: View {
    @StateObject private var gameState = GameState()
    
    @State private var scene: GameScene = {
        let s = GameScene()
        s.scaleMode = .resizeFill
        return s
    }()
    
    var body: some View {
        ZStack {
            AnimatedSpaceBackground(gameState: gameState)
                .ignoresSafeArea()
            
            if !gameState.isInMenu {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea()
                    .onAppear {
                        scene.gameState = gameState
                    }
                
                // Safe Area Compliant In-Game HUD
                VStack {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SCORE")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan.opacity(0.8))
                            Text("\(gameState.score)")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        if gameState.combo > 1 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.caption2)
                                Text("\(gameState.combo)x")
                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.yellow.opacity(0.18)))
                            .overlay(Capsule().stroke(Color.yellow.opacity(0.4), lineWidth: 1))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 5) {
                                ForEach(0..<3) { index in
                                    Image(systemName: index < gameState.lives ? "heart.fill" : "heart")
                                        .foregroundColor(index < gameState.lives ? .red : .white.opacity(0.2))
                                        .font(.system(size: 16))
                                }
                            }
                            
                            if !gameState.activePowerupText.isEmpty {
                                Text(gameState.activePowerupText)
                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                                    .foregroundColor(.yellow)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.yellow.opacity(0.2)))
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.black.opacity(0.65))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 50)
                    
                    Spacer()
                }
            } else {
                LandingView(gameState: gameState)
                    .transition(.opacity)
            }
            
            if gameState.isGameOver {
                GameOverModal(gameState: gameState, scene: scene)
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: gameState.isGameOver)
        .animation(.easeInOut(duration: 0.25), value: gameState.isInMenu)
    }
}

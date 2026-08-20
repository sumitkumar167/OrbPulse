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
            // Layer 1: Ambient Space Background (Always present)
            AnimatedSpaceBackground(gameState: gameState)
                .ignoresSafeArea()
            
            // Layer 2: Main Menu vs Active SpriteKit Gameplay
            if gameState.isInMenu {
                LandingView(gameState: gameState)
                    .transition(.opacity)
            } else {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea()
                    .onAppear {
                        scene.gameState = gameState
                        FeedbackManager.shared.warmUp()
                    }
                
                // In-game HUD (visible only during active play)
                if !gameState.isGameOver {
                    GameHUDView(gameState: gameState)
                        .transition(.opacity)
                }
            }
            
            // Layer 3: Game Over Modal (Always mounts on top when triggered)
            if gameState.isGameOver {
                GameOverModal(gameState: gameState, scene: scene)
                    .zIndex(999)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: gameState.isInMenu)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: gameState.isGameOver)
    }
}

// MARK: - Isolated HUD View
struct GameHUDView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack {
            HStack(alignment: .center) {
                // Score & High-score crown
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("SCORE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(gameState.hasBeatenHighScoreThisRun ? .yellow : .cyan.opacity(0.8))
                        
                        if gameState.hasBeatenHighScoreThisRun {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text("\(gameState.score)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Active Combo Streak Pill
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
                
                // Lives & Active Powerup Badges
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
    }
}

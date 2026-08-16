//
//  UIComponents.swift
//  OrbPulse
//
//  Created by Sumit Kumar on 16/08/26.
//
import SwiftUI

// MARK: - Zero-Stutter Space Background (With Subtle Record-Breaker Horizon)
struct AnimatedSpaceBackground: View {
    @ObservedObject var gameState: GameState
    
    @State private var starOffset: CGFloat = 0
    
    var isFever: Bool { gameState.isFeverActive }
    var isRecordRun: Bool { gameState.hasBeatenHighScoreThisRun }
    
    var body: some View {
        ZStack {
            // 1. Dark Base Obsidian Cosmos
            Color(red: 0.03, green: 0.03, blue: 0.06)
            
            // 2. Subtle High-Score Horizon Sheen (Smooth transition when breaking personal best)
            RadialGradient(
                colors: [
                    Color(red: 1.0, green: 0.82, blue: 0.28).opacity(isRecordRun ? 0.15 : 0.0),
                    Color.clear
                ],
                center: .bottom,
                startRadius: 10,
                endRadius: 450
            )
            .animation(.easeInOut(duration: 1.2), value: isRecordRun)
            
            // 3. Pulse Rush Glow Layer
            RadialGradient(
                colors: [Color.yellow.opacity(0.35), Color.clear],
                center: .bottom,
                startRadius: 20,
                endRadius: 400
            )
            .opacity(isFever ? 1.0 : 0.0)
            .animation(.linear(duration: 0.3), value: isFever)
            
            // 4. Default Ambient Horizon Glow
            LinearGradient(
                colors: [
                    Color.clear,
                    isRecordRun ? Color.yellow.opacity(0.12) : Color.cyan.opacity(0.12),
                    isRecordRun ? Color(red: 0.85, green: 0.45, blue: 0.15).opacity(0.18) : Color.purple.opacity(0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 260)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .opacity(isFever ? 0.0 : 1.0)
            .animation(.easeInOut(duration: 0.8), value: isRecordRun)
            .animation(.linear(duration: 0.3), value: isFever)
            
            // 5. Parallax Stars (Subtle golden stardust on record run)
            StarCanvas(isRecordRun: isRecordRun)
                .offset(y: starOffset)
                .animation(.easeInOut(duration: 1.0), value: isRecordRun)
        }
        .onAppear {
            withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                starOffset = 400
            }
        }
    }
}

private struct StarCanvas: View {
    var isRecordRun: Bool
    
    var body: some View {
        Canvas { ctx, size in
            for i in 0..<32 {
                let px = Double((i * 97) % 1000) / 1000.0 * size.width
                let py = Double((i * 137) % 1000) / 1000.0 * (size.height + 400) - 200
                let s = Double((i % 2) + 1)
                
                let rect = CGRect(x: px, y: py, width: s, height: s)
                
                // When in record run, every 3rd star takes on a subtle golden tint
                let starColor: Color
                if isRecordRun && (i % 3 == 0) {
                    starColor = Color(red: 1.0, green: 0.88, blue: 0.45).opacity(0.85)
                } else {
                    starColor = Color.white.opacity(0.65)
                }
                
                ctx.fill(Path(ellipseIn: rect), with: .color(starColor))
            }
        }
    }
}
// MARK: - Landing Page View
struct LandingView: View {
    @ObservedObject var gameState: GameState
    @State private var orbFloat = false
    @State private var glowPulse = false
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("ORB PULSE")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(glowPulse ? 0.9 : 0.4), radius: glowPulse ? 22 : 12)
                
                Text("REFLEX ARCADE")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .tracking(4)
                    .foregroundColor(.cyan.opacity(0.8))
            }
            .padding(.top, 50)
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [.cyan.opacity(0.25), .clear], center: .center, startRadius: 10, endRadius: 100))
                    .frame(width: 200, height: 200)
                
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .shadow(color: .cyan, radius: 14)
                    .offset(y: orbFloat ? -18 : 8)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.cyan)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 2))
                    .frame(width: 90, height: 16)
                    .shadow(color: .cyan.opacity(0.8), radius: 10)
                    .offset(y: 50)
            }
            .frame(height: 140)
            
            Spacer()
            
            HStack(spacing: 18) {
                legendItem(color: .cyan, label: "CATCH")
                legendItem(color: .red, label: "DODGE")
                legendItem(color: .green, label: "EXPAND")
                legendItem(color: .yellow, label: "RUSH")
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 22)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.1), lineWidth: 1))
            )
            .padding(.bottom, 24)
            
            if gameState.highScore > 0 {
                HStack(spacing: 18) {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text("BEST: \(gameState.highScore)")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    if gameState.lastScore > 0 {
                        Text("•").foregroundColor(.gray)
                        Text("LAST: \(gameState.lastScore)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 20)
            }
            
            Button(action: {
                gameState.isInMenu = false
                gameState.restartTrigger.toggle()
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                    Text("PLAY")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Capsule()
                        .fill(Color.cyan)
                        .shadow(color: .cyan.opacity(0.6), radius: 14, y: 4)
                )
            }
            .padding(.horizontal, 36)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                orbFloat = true
                glowPulse = true
            }
        }
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        VStack(spacing: 6) {
            Circle().fill(color).frame(width: 22, height: 22)
                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
            Text(label)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(color)
        }
    }
}

// MARK: - Game Over Modal (With Instant 1-Tap Anywhere Replay)
struct GameOverModal: View {
    @ObservedObject var gameState: GameState
    var scene: GameScene
    
    var isNewHigh: Bool {
        gameState.score >= gameState.highScore && gameState.score > 0
    }
    
    var body: some View {
        ZStack {
            // Tap background to instantly retry
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    triggerQuickRestart()
                }
            
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("GAME OVER")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    if isNewHigh {
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                            Text("NEW HIGH SCORE")
                        }
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.yellow.opacity(0.2)))
                    }
                }
                
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("FINAL SCORE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        Text("\(gameState.score)")
                            .font(.system(size: 52, weight: .black, design: .rounded))
                            .foregroundColor(.cyan)
                            .shadow(color: .cyan.opacity(0.5), radius: 12)
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    HStack(spacing: 32) {
                        VStack(spacing: 2) {
                            Text("BEST")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gray)
                            Text("\(gameState.highScore)")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 2) {
                            Text("MAX STREAK")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gray)
                            Text("\(gameState.maxStreak)x")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .foregroundColor(.yellow)
                        }
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.white.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.1), lineWidth: 1))
                )
                
                // Action Buttons
                HStack(spacing: 14) {
                    Button(action: {
                        gameState.lastScore = gameState.score
                        gameState.isGameOver = false
                        gameState.isInMenu = true
                        scene.clearScene()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "house.fill")
                            Text("MENU")
                        }
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.12)))
                    }
                    
                    Button(action: {
                        triggerQuickRestart()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("TAP TO RETRY")
                        }
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color.cyan).shadow(color: .cyan.opacity(0.5), radius: 10))
                    }
                }
                
                Text("TAP ANYWHERE TO REPLAY")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.35))
                    .padding(.top, -6)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(red: 0.08, green: 0.07, blue: 0.14))
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.12), lineWidth: 1))
                    .shadow(color: .black.opacity(0.6), radius: 30)
            )
            .padding(.horizontal, 24)
        }
    }
    
    private func triggerQuickRestart() {
        gameState.restartTrigger.toggle()
    }
}

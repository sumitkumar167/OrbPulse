import SwiftUI
import Combine

final class GameState: ObservableObject {
    @Published var score: Int = 0
    @Published var highScore: Int = UserDefaults.standard.integer(forKey: "OrbPulse_HighScore")
    @Published var lastScore: Int = 0
    @Published var lives: Int = 3
    @Published var combo: Int = 0
    @Published var maxStreak: Int = 0
    @Published var speedMultiplier: Double = 1.0
    @Published var isGameOver: Bool = false
    @Published var isInMenu: Bool = true
    @Published var restartTrigger: Bool = false
    @Published var activePowerupText: String = ""
    @Published var isFeverActive: Bool = false
    @Published var feverTimer: Double = 0.0
    
    func addScore(points: Int) {
        let multiplier = isFeverActive ? (max(1, combo / 4 + 1) * 2) : max(1, combo / 4 + 1)
        score += points * multiplier
        if combo > maxStreak {
            maxStreak = combo
        }
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: "OrbPulse_HighScore")
        }
    }
    
    func resetCombo() {
        combo = 0
        if isFeverActive {
            isFeverActive = false
        }
    }
}

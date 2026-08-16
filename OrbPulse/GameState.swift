import SwiftUI
import Combine

// MARK: - Paddle Skin Model
enum PaddleSkin: String, CaseIterable, Identifiable {
    case neonCyan = "Neon Cyan"
    case plasmaMagenta = "Plasma Magenta"
    case solarGold = "Solar Gold"
    case vaporViolet = "Vapor Violet"
    case hyperRed = "Hyper Red"
    
    var id: String { rawValue }
    
    var cost: Int {
        switch self {
        case .neonCyan: return 0
        case .plasmaMagenta: return 500
        case .solarGold: return 1500
        case .vaporViolet: return 3000
        case .hyperRed: return 5000
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .neonCyan: return .cyan
        case .plasmaMagenta: return Color(red: 1.0, green: 0.2, blue: 0.6)
        case .solarGold: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .vaporViolet: return Color(red: 0.7, green: 0.3, blue: 1.0)
        case .hyperRed: return Color(red: 1.0, green: 0.25, blue: 0.25)
        }
    }
    
    var uiColor: UIColor {
        switch self {
        case .neonCyan: return .systemCyan
        case .plasmaMagenta: return UIColor(red: 1.0, green: 0.2, blue: 0.6, alpha: 1.0)
        case .solarGold: return UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        case .vaporViolet: return UIColor(red: 0.7, green: 0.3, blue: 1.0, alpha: 1.0)
        case .hyperRed: return UIColor(red: 1.0, green: 0.25, blue: 0.25, alpha: 1.0)
        }
    }
}

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
    @Published var hasBeatenHighScoreThisRun: Bool = false
    
    // Currency & Locker
    @Published var stardust: Int = UserDefaults.standard.integer(forKey: "OrbPulse_Stardust")
    @Published var selectedSkin: PaddleSkin = {
        let saved = UserDefaults.standard.string(forKey: "OrbPulse_EquippedSkin") ?? PaddleSkin.neonCyan.rawValue
        return PaddleSkin(rawValue: saved) ?? .neonCyan
    }()
    @Published var unlockedSkins: [String] = {
        let saved = UserDefaults.standard.stringArray(forKey: "OrbPulse_UnlockedSkins") ?? [PaddleSkin.neonCyan.rawValue]
        return saved
    }()
    
    func addScore(points: Int) -> Bool {
        let multiplier = isFeverActive ? (max(1, combo / 4 + 1) * 2) : max(1, combo / 4 + 1)
        let earnedPoints = points * multiplier
        score += earnedPoints
        
        // Award Stardust (1 Stardust per 10 points scored)
        let earnedStardust = max(1, earnedPoints / 10)
        addStardust(amount: earnedStardust)
        
        if combo > maxStreak {
            maxStreak = combo
        }
        
        if highScore > 0 && score > highScore && !hasBeatenHighScoreThisRun {
            hasBeatenHighScoreThisRun = true
            highScore = score
            UserDefaults.standard.set(highScore, forKey: "OrbPulse_HighScore")
            return true
        }
        
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: "OrbPulse_HighScore")
        }
        
        return false
    }
    
    func addStardust(amount: Int) {
        stardust += amount
        UserDefaults.standard.set(stardust, forKey: "OrbPulse_Stardust")
    }
    
    func unlockSkin(_ skin: PaddleSkin) -> Bool {
        if stardust >= skin.cost && !unlockedSkins.contains(skin.rawValue) {
            stardust -= skin.cost
            UserDefaults.standard.set(stardust, forKey: "OrbPulse_Stardust")
            unlockedSkins.append(skin.rawValue)
            UserDefaults.standard.set(unlockedSkins, forKey: "OrbPulse_UnlockedSkins")
            equipSkin(skin)
            return true
        }
        return false
    }
    
    func equipSkin(_ skin: PaddleSkin) {
        if unlockedSkins.contains(skin.rawValue) {
            selectedSkin = skin
            UserDefaults.standard.set(skin.rawValue, forKey: "OrbPulse_EquippedSkin")
        }
    }
    
    func resetCombo() {
        combo = 0
        if isFeverActive {
            isFeverActive = false
        }
    }
}

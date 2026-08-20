import SpriteKit
import UIKit

// MARK: - Orb Entity Types
/// Defines the distinct categories of orbs falling through the gameplay scene.
enum OrbType {
    case target
    case hazard
    case wide
    case magnet
    case feverGold
    
    /// Unique identifier string used for node identification and collision routing.
    var identifier: String {
        switch self {
        case .target: return "targetOrb"
        case .hazard: return "hazardOrb"
        case .wide: return "wideOrb"
        case .magnet: return "magnetOrb"
        case .feverGold: return "feverGoldOrb"
        }
    }
    
    /// The signature neon chromatic value representing the orb.
    var color: UIColor {
        switch self {
        case .target: return .systemCyan
        case .hazard: return .systemRed
        case .wide: return .systemGreen
        case .magnet: return .systemYellow
        case .feverGold: return UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        }
    }
}

// MARK: - Game Scene Implementation
/// Core SpriteKit rendering and physics simulation loop for the Orb Pulse arcade experience.
final class GameScene: SKScene {
    
    // MARK: - Public Properties
    /// Weak reference to the shared SwiftUI reactive game state container.
    weak var gameState: GameState?
    
    // MARK: - Scene State
    private var isPlaying = false
    private var timeElapsed: TimeInterval = 0
    private var lastSpawnTime: TimeInterval = 0
    private var spawnInterval: TimeInterval = 0.85
    private var fallDuration: Double = 3.2
    
    // MARK: - Paddle Architecture
    private var paddleContainer: SKNode!
    private var paddleChassis: SKShapeNode!
    private var paddleCore: SKShapeNode!
    private var plasmaEngineEmitter: SKEmitterNode?
    
    // MARK: - Dimensions & Physical Constants
    private let defaultPaddleWidth: CGFloat = 114.0
    private var currentPaddleWidth: CGFloat = 114.0
    private let paddleHeight: CGFloat = 18.0
    private let paddleYPosition: CGFloat = 120.0
    
    // MARK: - Powerup & Mode Lifecycles
    private var isMagnetActive = false
    private var isWideActive = false
    private var feverTimeRemaining: Double = 0.0
    
    // MARK: - Motion Throttle State
    private var lastTouchX: CGFloat = 0
    private var currentVelocityX: CGFloat = 0
    
    // MARK: - Cached Assets & Prototypes
    private var particleTexture: SKTexture?
    private var templateEmitter: SKEmitterNode?
    
    // MARK: - Lifecycle Hooks
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        view.allowsTransparency = true
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        FeedbackManager.shared.warmUp()
        
        createParticleTexture(in: view)
        setupTemplateEmitter()
        preWarmFontAtlas()
        setupPaddle()
    }
    
    // MARK: - Asset Pre-Warming
    /// Renders a radial gradient texture for smooth, GPU-accelerated particle blending.
    private func createParticleTexture(in view: SKView) {
        let size = CGSize(width: 32, height: 32)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let center = CGPoint(x: 16, y: 16)
            let colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0.0).cgColor] as CFArray
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
                ctx.cgContext.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: 16, options: [])
            }
        }
        particleTexture = SKTexture(image: img)
    }
    
    /// Pre-configures a shared prototype emitter to avoid runtime instantiation latency.
    private func setupTemplateEmitter() {
        let emitter = SKEmitterNode()
        emitter.particleTexture = particleTexture
        emitter.particleBirthRate = 140
        emitter.particleLifetime = 0.24
        emitter.particleLifetimeRange = 0.06
        emitter.particlePositionRange = CGVector(dx: 26, dy: 4)
        emitter.particleSpeed = 35
        emitter.particleSpeedRange = 12
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 14
        emitter.particleScale = 0.85
        emitter.particleScaleRange = 0.15
        emitter.particleScaleSpeed = -2.6
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -3.2
        emitter.particleBlendMode = .add
        emitter.particleColorBlendFactor = 1.0
        templateEmitter = emitter
    }
    
    /// Pre-rasterizes CoreText glyph textures to guarantee hitch-free font rendering during gameplay.
    private func preWarmFontAtlas() {
        let dummyLabel = SKLabelNode(text: "⚡️ PULSE RUSH ⚡️ PERFECT! +25 👑 NEW RECORD! 👑")
        dummyLabel.fontName = "AvenirNext-Heavy"
        dummyLabel.fontSize = 15
        dummyLabel.alpha = 0.001
        dummyLabel.position = CGPoint(x: -500, y: -500)
        addChild(dummyLabel)
    }
    
    // MARK: - Paddle Assembly
    /// Builds the retro-futuristic spacecraft paddle with cybernetic geometry and plasma under-glow.
    private func setupPaddle() {
        paddleContainer?.removeFromParent()
        paddleContainer = SKNode()
        paddleContainer.position = CGPoint(x: size.width / 2, y: paddleYPosition)
        paddleContainer.zPosition = 100
        paddleContainer.isHidden = true
        addChild(paddleContainer)
        
        currentPaddleWidth = defaultPaddleWidth
        
        // 1. Aerodynamic Carbon-Fiber Chassis
        paddleChassis = SKShapeNode()
        paddleChassis.path = createCyberpunkPath(width: currentPaddleWidth, height: paddleHeight)
        paddleChassis.fillColor = UIColor(red: 0.06, green: 0.07, blue: 0.11, alpha: 0.96)
        paddleChassis.strokeColor = gameState?.selectedSkin.uiColor ?? .cyan
        paddleChassis.lineWidth = 2.0
        paddleContainer.addChild(paddleChassis)
        
        // 2. Luminous Neon Plasma Core
        paddleCore = SKShapeNode(rectOf: CGSize(width: currentPaddleWidth - 28, height: 4), cornerRadius: 2)
        paddleCore.fillColor = gameState?.selectedSkin.uiColor ?? .cyan
        paddleCore.strokeColor = .white
        paddleCore.lineWidth = 1.0
        paddleCore.position = CGPoint(x: 0, y: 0)
        paddleContainer.addChild(paddleCore)
        
        // 3. Continuous Under-Engine Plasma Exhaust Plume
        setupPlasmaEngine()
    }
    
    /// Assembles the unified under-engine plasma plume with dynamic throttle control.
    private func setupPlasmaEngine() {
        plasmaEngineEmitter?.removeFromParent()
        
        let emitter = SKEmitterNode()
        emitter.particleTexture = particleTexture
        emitter.particleBirthRate = 50
        emitter.particleLifetime = 0.18
        emitter.particleLifetimeRange = 0.04
        emitter.particlePositionRange = CGVector(dx: currentPaddleWidth * 0.65, dy: 2)
        emitter.particleSpeed = 25
        emitter.particleSpeedRange = 10
        emitter.emissionAngle = -.pi / 2
        emitter.emissionAngleRange = .pi / 16
        emitter.particleScale = 0.55
        emitter.particleScaleSpeed = -1.8
        emitter.particleAlpha = 0.65
        emitter.particleColor = gameState?.selectedSkin.uiColor ?? .cyan
        emitter.particleBlendMode = .add
        emitter.position = CGPoint(x: 0, y: -paddleHeight / 2)
        emitter.targetNode = self
        emitter.zPosition = -1
        
        paddleContainer.addChild(emitter)
        plasmaEngineEmitter = emitter
    }
    
    /// Generates a beveled, aerodynamic polygon path for the retro spacecraft.
    private func createCyberpunkPath(width: CGFloat, height: CGFloat) -> CGPath {
        let halfW = width / 2
        let halfH = height / 2
        let bevel: CGFloat = 6.0
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -halfW + bevel, y: halfH))
        path.addLine(to: CGPoint(x: halfW - bevel, y: halfH))
        path.addLine(to: CGPoint(x: halfW, y: halfH - bevel))
        path.addLine(to: CGPoint(x: halfW - (bevel * 0.75), y: -halfH + bevel))
        path.addLine(to: CGPoint(x: halfW - bevel * 2, y: -halfH))
        path.addLine(to: CGPoint(x: -halfW + bevel * 2, y: -halfH))
        path.addLine(to: CGPoint(x: -halfW + (bevel * 0.75), y: -halfH + bevel))
        path.addLine(to: CGPoint(x: -halfW, y: halfH - bevel))
        path.closeSubpath()
        return path
    }
    
    // MARK: - Game Lifecycle Controls
    /// Purges all active gameplay orbs and particle instances from the visual hierarchy.
    func clearScene() {
        isPlaying = false
        feverTimeRemaining = 0
        isWideActive = false
        isMagnetActive = false
        paddleContainer?.isHidden = true
        paddleContainer?.zRotation = 0
        
        for child in children where child !== paddleContainer {
            if child.alpha > 0.01 {
                child.removeFromParent()
            }
        }
    }
    
    /// Resets scores, multipliers, paddle geometry, and boots the main game loop.
    func startGame() {
        clearScene()
        
        gameState?.score = 0
        gameState?.lives = 3
        gameState?.combo = 0
        gameState?.maxStreak = 0
        gameState?.speedMultiplier = 1.0
        gameState?.isGameOver = false
        gameState?.isFeverActive = false
        gameState?.hasBeatenHighScoreThisRun = false
        gameState?.activePowerupText = ""
        
        timeElapsed = 0
        lastSpawnTime = 0
        spawnInterval = 0.85
        fallDuration = 3.2
        isMagnetActive = false
        isWideActive = false
        feverTimeRemaining = 0
        currentVelocityX = 0
        
        updatePaddleWidth(to: defaultPaddleWidth)
        paddleContainer.position.x = size.width / 2
        lastTouchX = paddleContainer.position.x
        refreshPaddleAesthetics()
        
        paddleContainer.isHidden = false
        isPlaying = true
    }
    
    // MARK: - Touch Interaction & Throttle Mechanics
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        lastTouchX = touch.location(in: self).x
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isPlaying, let touch = touches.first else { return }
        let location = touch.location(in: self)
        let halfWidth = currentPaddleWidth / 2
        let clampedX = max(halfWidth + 10, min(size.width - halfWidth - 10, location.x))
        
        // Calculate instantaneous horizontal velocity for dynamic engine throttling
        let dx = clampedX - paddleContainer.position.x
        currentVelocityX = dx
        paddleContainer.position.x = clampedX
        lastTouchX = clampedX
        
        // Dynamic Throttle: Increase engine burn rate and particle speed on movement
        applyEngineThrottle(intensity: min(1.0, abs(dx) / 12.0))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        settleEngineToIdle()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        settleEngineToIdle()
    }
    
    /// Elevates thruster particle output and banking angle based on finger motion velocity.
    private func applyEngineThrottle(intensity: CGFloat) {
        guard let emitter = plasmaEngineEmitter else { return }
        
        let targetBirthRate = 50.0 + (Double(intensity) * 140.0)
        let targetSpeed = 25.0 + (Double(intensity) * 60.0)
        
        emitter.particleBirthRate = targetBirthRate
        emitter.particleSpeed = targetSpeed
        
        // Subtle banking tilt toward the direction of travel
        let bankAngle = -currentVelocityX * 0.004
        let clampedAngle = max(-0.12, min(0.12, bankAngle))
        paddleContainer.run(SKAction.rotate(toAngle: clampedAngle, duration: 0.05, shortestUnitArc: true))
    }
    
    /// Smoothly transitions engine emissions back to idle hover dynamics.
    private func settleEngineToIdle() {
        plasmaEngineEmitter?.particleBirthRate = 50
        plasmaEngineEmitter?.particleSpeed = 25
        paddleContainer.run(SKAction.rotate(toAngle: 0, duration: 0.15, shortestUnitArc: true))
    }
    
    // MARK: - Frame Update Loop
    override func update(_ currentTime: TimeInterval) {
        guard let gameState = gameState else { return }
        
        if gameState.restartTrigger {
            gameState.restartTrigger = false
            startGame()
        }
        
        guard isPlaying, !gameState.isInMenu else { return }
        
        timeElapsed += 1.0 / 60.0
        let currentMultiplier = 1.0 + (timeElapsed / 28.0)
        gameState.speedMultiplier = currentMultiplier
        
        // Fever countdown lifecycle
        if feverTimeRemaining > 0 {
            feverTimeRemaining -= 1.0 / 60.0
            gameState.feverTimer = feverTimeRemaining
            if feverTimeRemaining <= 0 {
                endFeverMode()
            }
        }
        
        // Adaptive spawn and fall rate scaling
        let baseSpawn = (feverTimeRemaining > 0) ? 0.35 : 0.85
        let baseFall = (feverTimeRemaining > 0) ? 2.4 : 3.2
        
        spawnInterval = max(0.20, baseSpawn / currentMultiplier)
        fallDuration = max(1.1, baseFall / currentMultiplier)
        
        if currentTime - lastSpawnTime > spawnInterval {
            spawnOrb()
            lastSpawnTime = currentTime
        }
        
        checkPaddleCollisions()
        purgeOffscreenEntities()
    }
    
    // MARK: - Entity Spawning
    private func spawnOrb() {
        let isFever = feverTimeRemaining > 0
        let orbType: OrbType
        
        if isFever {
            orbType = .feverGold
        } else {
            let roll = Int.random(in: 1...100)
            if roll <= 16 {
                orbType = .hazard
            } else if roll <= 23 {
                orbType = .wide
            } else if roll <= 30 {
                orbType = .magnet
            } else {
                orbType = .target
            }
        }
        
        let radius: CGFloat = 17.0
        let orb = SKShapeNode(circleOfRadius: radius)
        let spawnY = size.height - 110
        let randomX = CGFloat.random(in: (radius + 20)...(size.width - radius - 20))
        
        orb.position = CGPoint(x: randomX, y: spawnY)
        orb.name = orbType.identifier
        orb.fillColor = orbType.color
        orb.strokeColor = .white
        orb.lineWidth = 2.0
        orb.zPosition = 10
        
        // Attach cloned particle exhaust trail
        if let template = templateEmitter, let emitter = template.copy() as? SKEmitterNode {
            emitter.particleColor = orbType.color
            emitter.targetNode = self
            emitter.zPosition = -1
            orb.addChild(emitter)
        }
        
        addChild(orb)
        
        let moveDown = SKAction.moveTo(y: paddleYPosition - 45, duration: fallDuration)
        orb.run(moveDown)
    }
    
    // MARK: - Collision Detection & Entity Handling
    private func checkPaddleCollisions() {
        let paddleFrame = CGRect(
            x: paddleContainer.position.x - currentPaddleWidth / 2 - 4,
            y: paddleContainer.position.y - paddleHeight / 2 - 4,
            width: currentPaddleWidth + 8,
            height: paddleHeight + 8
        )
        
        for child in children where child !== paddleContainer && child.name != "floatingText" && child.alpha > 0.01 {
            guard let orb = child as? SKShapeNode, let name = orb.name else { continue }
            
            // Magnet & Fever attraction mechanics
            if (isMagnetActive || feverTimeRemaining > 0) && (name == OrbType.target.identifier || name == OrbType.feverGold.identifier) && orb.position.y < size.height * 0.65 {
                let dx = paddleContainer.position.x - orb.position.x
                orb.position.x += dx * 0.10
            }
            
            if paddleFrame.contains(orb.position) || paddleFrame.intersects(orb.frame) {
                let distanceFromCenter = abs(orb.position.x - paddleContainer.position.x)
                let isEdgeDeflection = distanceFromCenter > (currentPaddleWidth * 0.36)
                handleCatch(orb: orb, identifier: name, isEdge: isEdgeDeflection)
            }
        }
    }
    
    private func handleCatch(orb: SKShapeNode, identifier: String, isEdge: Bool) {
        switch identifier {
        case OrbType.target.identifier:
            gameState?.combo += isEdge ? 2 : 1
            let points = isEdge ? 25 : 10
            let brokeRecord = gameState?.addScore(points: points) ?? false
            
            if brokeRecord {
                triggerNewRecordCelebration()
            }
            
            if isEdge {
                showFloatingText(text: "PERFECT! +25", color: .cyan, at: orb.position)
                shakeScreen(magnitude: 6)
                FeedbackManager.shared.playEdgeCatch()
            } else {
                FeedbackManager.shared.playCatch(combo: gameState?.combo ?? 1)
            }
            
            createBurstEffect(at: orb.position, color: .cyan)
            orb.removeFromParent()
            
            if let combo = gameState?.combo, combo > 0 && (combo % 20 == 0) && feverTimeRemaining <= 0 {
                startFeverMode()
            }
            
        case OrbType.feverGold.identifier:
            gameState?.combo += 1
            let brokeRecord = gameState?.addScore(points: 30) ?? false
            if brokeRecord {
                triggerNewRecordCelebration()
            }
            FeedbackManager.shared.playGoldCatch()
            createBurstEffect(at: orb.position, color: .yellow)
            orb.removeFromParent()
            
        case OrbType.wide.identifier:
            gameState?.activePowerupText = "WIDE"
            FeedbackManager.shared.playPowerup()
            createBurstEffect(at: orb.position, color: .green)
            orb.removeFromParent()
            triggerWidePaddle()
            
        case OrbType.magnet.identifier:
            gameState?.activePowerupText = "MAGNET"
            FeedbackManager.shared.playPowerup()
            createBurstEffect(at: orb.position, color: .yellow)
            orb.removeFromParent()
            triggerMagnet()
            
        case OrbType.hazard.identifier:
            FeedbackManager.shared.playHazard()
            createBurstEffect(at: orb.position, color: .red)
            orb.removeFromParent()
            loseLife()
            
        default:
            break
        }
    }
    
    private func purgeOffscreenEntities() {
        for child in children {
            if child.position.y < (paddleYPosition - 35) && child !== paddleContainer && child.name != "floatingText" && child.alpha > 0.01 {
                if child.name == OrbType.target.identifier && feverTimeRemaining <= 0 {
                    loseLife()
                }
                child.removeFromParent()
            }
        }
    }
    
    // MARK: - Powerups & Special Modes
    private func startFeverMode() {
        feverTimeRemaining = 5.0
        gameState?.isFeverActive = true
        gameState?.activePowerupText = "PULSE RUSH!"
        refreshPaddleAesthetics()
        showFloatingText(text: "⚡️ PULSE RUSH ⚡️", color: .yellow, at: CGPoint(x: size.width / 2, y: size.height / 2))
        shakeScreen(magnitude: 10)
        FeedbackManager.shared.playPulseRushFanfare()
    }
    
    private func endFeverMode() {
        gameState?.isFeverActive = false
        if gameState?.activePowerupText == "PULSE RUSH!" {
            gameState?.activePowerupText = ""
        }
        refreshPaddleAesthetics()
        FeedbackManager.shared.resetFeverStreak()
    }
    
    private func triggerWidePaddle() {
        isWideActive = true
        updatePaddleWidth(to: defaultPaddleWidth * 1.6)
        refreshPaddleAesthetics()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
            guard let self = self else { return }
            self.isWideActive = false
            self.updatePaddleWidth(to: self.defaultPaddleWidth)
            self.refreshPaddleAesthetics()
            if self.gameState?.activePowerupText == "WIDE" {
                self.gameState?.activePowerupText = ""
            }
        }
    }
    
    private func triggerMagnet() {
        isMagnetActive = true
        refreshPaddleAesthetics()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
            guard let self = self else { return }
            self.isMagnetActive = false
            self.refreshPaddleAesthetics()
            if self.gameState?.activePowerupText == "MAGNET" {
                self.gameState?.activePowerupText = ""
            }
        }
    }
    
    private func loseLife() {
        guard let gameState = gameState, isPlaying else { return }
        gameState.lives -= 1
        gameState.resetCombo()
        FeedbackManager.shared.playHazard()
        shakeScreen(magnitude: 10)
        
        if gameState.lives <= 0 {
            gameOver()
        }
    }
    
    // MARK: - Geometry & Aesthetics Mutators
    private func updatePaddleWidth(to newWidth: CGFloat) {
        currentPaddleWidth = newWidth
        paddleChassis.path = createCyberpunkPath(width: newWidth, height: paddleHeight)
        
        let corePath = CGPath(
            roundedRect: CGRect(x: -(newWidth - 28) / 2, y: -2, width: newWidth - 28, height: 4),
            cornerWidth: 2,
            cornerHeight: 2,
            transform: nil
        )
        paddleCore.path = corePath
        plasmaEngineEmitter?.particlePositionRange = CGVector(dx: newWidth * 0.65, dy: 2)
    }
    
    private func refreshPaddleAesthetics() {
        let skinColor = gameState?.selectedSkin.uiColor ?? .cyan
        
        if feverTimeRemaining > 0 {
            paddleChassis.strokeColor = UIColor(red: 1.0, green: 0.88, blue: 0.2, alpha: 1.0)
            paddleChassis.lineWidth = 3.0
            paddleCore.fillColor = .yellow
            plasmaEngineEmitter?.particleColor = .yellow
        } else if isMagnetActive {
            paddleChassis.strokeColor = .systemYellow
            paddleChassis.lineWidth = 2.5
            paddleCore.fillColor = .systemYellow
            plasmaEngineEmitter?.particleColor = .systemYellow
        } else if isWideActive {
            paddleChassis.strokeColor = .systemGreen
            paddleChassis.lineWidth = 2.5
            paddleCore.fillColor = .systemGreen
            plasmaEngineEmitter?.particleColor = .systemGreen
        } else {
            paddleChassis.strokeColor = skinColor
            paddleChassis.lineWidth = 2.0
            paddleCore.fillColor = skinColor
            plasmaEngineEmitter?.particleColor = skinColor
        }
    }
    
    // MARK: - Visual Feedback FX
    private func showFloatingText(text: String, color: UIColor, at position: CGPoint) {
        let label = SKLabelNode(text: text)
        label.name = "floatingText"
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 15
        label.fontColor = color
        label.position = position
        label.zPosition = 150
        addChild(label)
        
        let moveUp = SKAction.moveBy(x: 0, y: 35, duration: 0.45)
        let fadeOut = SKAction.fadeOut(withDuration: 0.45)
        let group = SKAction.group([moveUp, fadeOut])
        let remove = SKAction.removeFromParent()
        label.run(SKAction.sequence([group, remove]))
    }
    
    private func triggerNewRecordCelebration() {
        FeedbackManager.shared.playNewRecordFanfare()
        showFloatingText(text: "👑 NEW RECORD! 👑", color: .yellow, at: CGPoint(x: size.width / 2, y: size.height * 0.55))
        shakeScreen(magnitude: 10)
        
        for _ in 0..<24 {
            let spark = SKShapeNode(rectOf: CGSize(width: 4, height: 8))
            spark.fillColor = (Bool.random() ? UIColor.yellow : UIColor.cyan)
            spark.strokeColor = .clear
            spark.position = CGPoint(x: size.width / 2, y: size.height * 0.55)
            spark.zPosition = 200
            addChild(spark)
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 60...140)
            let dest = CGPoint(
                x: spark.position.x + cos(angle) * distance,
                y: spark.position.y + sin(angle) * distance
            )
            
            let move = SKAction.move(to: dest, duration: 0.4)
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -4...4), duration: 0.4)
            let fade = SKAction.fadeOut(withDuration: 0.4)
            let group = SKAction.group([move, rotate, fade])
            let remove = SKAction.removeFromParent()
            spark.run(SKAction.sequence([group, remove]))
        }
    }
    
    private func shakeScreen(magnitude: CGFloat = 10) {
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -magnitude, y: 0, duration: 0.03),
            SKAction.moveBy(x: magnitude * 2, y: 0, duration: 0.03),
            SKAction.moveBy(x: -magnitude, y: 0, duration: 0.03)
        ])
        run(shake)
    }
    
    private func createBurstEffect(at position: CGPoint, color: UIColor) {
        for _ in 0..<12 {
            let spark = SKShapeNode(circleOfRadius: 2.5)
            spark.fillColor = color
            spark.strokeColor = .clear
            spark.position = position
            spark.zPosition = 20
            addChild(spark)
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 25...50)
            let destination = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )
            
            let move = SKAction.move(to: destination, duration: 0.18)
            let fade = SKAction.fadeOut(withDuration: 0.18)
            let group = SKAction.group([move, fade])
            let remove = SKAction.removeFromParent()
            spark.run(SKAction.sequence([group, remove]))
        }
    }
    
    private func gameOver() {
        isPlaying = false
        clearScene()
        gameState?.isGameOver = true
    }
}

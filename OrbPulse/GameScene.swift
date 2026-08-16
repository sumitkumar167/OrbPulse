import SpriteKit
import UIKit

enum OrbType {
    case target
    case hazard
    case wide
    case magnet
    case feverGold
    
    var identifier: String {
        switch self {
        case .target: return "targetOrb"
        case .hazard: return "hazardOrb"
        case .wide: return "wideOrb"
        case .magnet: return "magnetOrb"
        case .feverGold: return "feverGoldOrb"
        }
    }
    
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

final class GameScene: SKScene {
    weak var gameState: GameState?
    
    private var isPlaying = false
    private var timeElapsed: TimeInterval = 0
    private var lastSpawnTime: TimeInterval = 0
    private var spawnInterval: TimeInterval = 0.85
    private var fallDuration: Double = 3.2
    
    private var paddleNode: SKShapeNode!
    private var dangerLineNode: SKShapeNode!
    private var particleTexture: SKTexture?
    
    // Pre-configured template emitter for instant zero-lag cloning
    private var templateEmitter: SKEmitterNode?
    
    private let defaultPaddleWidth: CGFloat = 110.0
    private var currentPaddleWidth: CGFloat = 110.0
    private let paddleHeight: CGFloat = 18.0
    private let paddleYPosition: CGFloat = 120.0
    
    private var isMagnetActive = false
    private var feverTimeRemaining: Double = 0.0
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        view.allowsTransparency = true
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        FeedbackManager.shared.warmUp()
        
        createParticleTexture(in: view)
        setupTemplateEmitter()
        preWarmFontAtlas() // ⚡️ Pre-rasterizes CoreText glyphs for zero-frame drop
        
        setupDangerLine()
        setupPaddle()
    }
    
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
    
    // Pre-create archetype emitter so runtime spawns only perform lightweight copies
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
    
    // Pre-loads AvenirNext font textures into SpriteKit's GPU cache
    private func preWarmFontAtlas() {
        let dummyLabel = SKLabelNode(text: "⚡️ PULSE RUSH ⚡️ PERFECT! +25 👑 NEW RECORD! 👑")
        dummyLabel.fontName = "AvenirNext-Heavy"
        dummyLabel.fontSize = 15
        dummyLabel.alpha = 0.001
        dummyLabel.position = CGPoint(x: -500, y: -500)
        addChild(dummyLabel)
    }
    
    private func setupDangerLine() {
        dangerLineNode?.removeFromParent()
        dangerLineNode = SKShapeNode(rectOf: CGSize(width: size.width, height: 1.5))
        dangerLineNode.position = CGPoint(x: size.width / 2, y: paddleYPosition - 20)
        dangerLineNode.fillColor = UIColor.cyan.withAlphaComponent(0.2)
        dangerLineNode.strokeColor = .clear
        dangerLineNode.zPosition = 1
        addChild(dangerLineNode)
    }
    
    private func setupPaddle() {
        paddleNode?.removeFromParent()
        currentPaddleWidth = defaultPaddleWidth
        
        paddleNode = SKShapeNode(rectOf: CGSize(width: currentPaddleWidth, height: paddleHeight), cornerRadius: 9)
        paddleNode.fillColor = gameState?.selectedSkin.uiColor ?? .cyan
        paddleNode.strokeColor = .white
        paddleNode.lineWidth = 2.5
        paddleNode.position = CGPoint(x: size.width / 2, y: paddleYPosition)
        paddleNode.zPosition = 100
        paddleNode.isHidden = true
        addChild(paddleNode)
    }
    
    func clearScene() {
        isPlaying = false
        feverTimeRemaining = 0
        paddleNode?.isHidden = true
        dangerLineNode?.isHidden = true
        for child in children where child !== paddleNode && child !== dangerLineNode {
            if child.alpha > 0.01 { // Keep dummy warming nodes
                child.removeFromParent()
            }
        }
    }
    
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
        feverTimeRemaining = 0
        
        updatePaddleWidth(to: defaultPaddleWidth)
        paddleNode.position.x = size.width / 2
        paddleNode.fillColor = gameState?.selectedSkin.uiColor ?? .cyan
        paddleNode.isHidden = false
        dangerLineNode?.isHidden = false
        isPlaying = true
    }
    
    private func updatePaddleWidth(to newWidth: CGFloat) {
        currentPaddleWidth = newWidth
        let path = CGPath(
            roundedRect: CGRect(x: -newWidth / 2, y: -paddleHeight / 2, width: newWidth, height: paddleHeight),
            cornerWidth: 9,
            cornerHeight: 9,
            transform: nil
        )
        paddleNode.path = path
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isPlaying, let touch = touches.first else { return }
        let location = touch.location(in: self)
        let halfWidth = currentPaddleWidth / 2
        let clampedX = max(halfWidth + 10, min(size.width - halfWidth - 10, location.x))
        paddleNode.position.x = clampedX
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesMoved(touches, with: event)
    }
    
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
        
        if feverTimeRemaining > 0 {
            feverTimeRemaining -= 1.0 / 60.0
            gameState.feverTimer = feverTimeRemaining
            if feverTimeRemaining <= 0 {
                endFeverMode()
            }
        }
        
        let baseSpawn = (feverTimeRemaining > 0) ? 0.35 : 0.85
        let baseFall = (feverTimeRemaining > 0) ? 2.4 : 3.2
        
        spawnInterval = max(0.20, baseSpawn / currentMultiplier)
        fallDuration = max(1.1, baseFall / currentMultiplier)
        
        if currentTime - lastSpawnTime > spawnInterval {
            spawnOrb()
            lastSpawnTime = currentTime
        }
        
        checkPaddleCollisions()
        
        for child in children {
            if child.position.y < (paddleYPosition - 35) && child !== paddleNode && child !== dangerLineNode && child.name != "floatingText" && child.alpha > 0.01 {
                if child.name == OrbType.target.identifier && feverTimeRemaining <= 0 {
                    loseLife()
                }
                child.removeFromParent()
            }
        }
    }
    
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
        
        // Fast template cloning
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
    
    private func checkPaddleCollisions() {
        let paddleFrame = paddleNode.frame.insetBy(dx: -4, dy: -4)
        
        for child in children where child !== paddleNode && child !== dangerLineNode && child.name != "floatingText" && child.alpha > 0.01 {
            guard let orb = child as? SKShapeNode, let name = orb.name else { continue }
            
            if (isMagnetActive || feverTimeRemaining > 0) && (name == OrbType.target.identifier || name == OrbType.feverGold.identifier) && orb.position.y < size.height * 0.65 {
                let dx = paddleNode.position.x - orb.position.x
                orb.position.x += dx * 0.10
            }
            
            if paddleFrame.contains(orb.position) || paddleFrame.intersects(orb.frame) {
                let distanceFromCenter = abs(orb.position.x - paddleNode.position.x)
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
    
    private func startFeverMode() {
        feverTimeRemaining = 5.0
        gameState?.isFeverActive = true
        gameState?.activePowerupText = "PULSE RUSH!"
        paddleNode.fillColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        showFloatingText(text: "⚡️ PULSE RUSH ⚡️", color: .yellow, at: CGPoint(x: size.width / 2, y: size.height / 2))
        shakeScreen(magnitude: 10)
        FeedbackManager.shared.playPulseRushFanfare()
    }
    
    private func endFeverMode() {
        gameState?.isFeverActive = false
        if gameState?.activePowerupText == "PULSE RUSH!" {
            gameState?.activePowerupText = ""
        }
        paddleNode.fillColor = gameState?.selectedSkin.uiColor ?? .cyan
        FeedbackManager.shared.resetFeverStreak()
    }
    
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
    
    private func triggerWidePaddle() {
        updatePaddleWidth(to: defaultPaddleWidth * 1.6)
        paddleNode.fillColor = .systemGreen
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
            guard let self = self else { return }
            self.updatePaddleWidth(to: self.defaultPaddleWidth)
            self.paddleNode.fillColor = (self.feverTimeRemaining > 0) ? .yellow : (self.gameState?.selectedSkin.uiColor ?? .cyan)
            if self.gameState?.activePowerupText == "WIDE" {
                self.gameState?.activePowerupText = ""
            }
        }
    }
    
    private func triggerMagnet() {
        isMagnetActive = true
        paddleNode.strokeColor = .yellow
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
            guard let self = self else { return }
            self.isMagnetActive = false
            self.paddleNode.strokeColor = .white
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
    
    private func shakeScreen(magnitude: CGFloat = 10) {
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -magnitude, y: 0, duration: 0.03),
            SKAction.moveBy(x: magnitude * 2, y: 0, duration: 0.03),
            SKAction.moveBy(x: -magnitude, y: 0, duration: 0.03)
        ])
        run(shake)
    }
    
    private func gameOver() {
        isPlaying = false
        clearScene()
        gameState?.isGameOver = true
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
}

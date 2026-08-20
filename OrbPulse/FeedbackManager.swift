import AVFoundation
import UIKit

// MARK: - Arcade Audio & Haptics Engine
final class FeedbackManager {
    static let shared = FeedbackManager()
    
    // MARK: - Engine Architecture
    private var audioEngine = AVAudioEngine()
    private var sfxPlayerNodes: [AVAudioPlayerNode] = []
    private var sfxIndex = 0
    private let sfxNodeCount = 12
    
    // Dedicated Looping BGM Player Node
    private var bgmPlayerNode = AVAudioPlayerNode()
    
    private let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)!
    
    // MARK: - Haptic Drivers
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    // MARK: - Cached PCM Buffers
    private var catchBuffers: [AVAudioPCMBuffer] = []
    private var goldPoolBuffers: [AVAudioPCMBuffer] = []
    private var edgeBuffer: AVAudioPCMBuffer?
    private var hazardBuffer: AVAudioPCMBuffer?
    private var powerupBuffer: AVAudioPCMBuffer?
    private var fanfareBuffer: AVAudioPCMBuffer?
    private var buttonClickBuffer: AVAudioPCMBuffer?
    private var gameOverBuffer: AVAudioPCMBuffer?
    private var bgmLoopBuffer: AVAudioPCMBuffer?
    
    private var lastGoldNoteIndex = -1
    private var isBgmPlaying = false
    
    private init() {
        setupAudioSession()
        prepareHaptics()
        setupAudioEngine()
        preRenderBuffers()
        startAmbientBGM()
    }
    
    // MARK: - Eager Initialization
    func warmUp() {
        prepareHaptics()
        if !isBgmPlaying {
            startAmbientBGM()
        }
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio Session Setup Error: \(error.localizedDescription)")
        }
    }
    
    private func prepareHaptics() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        rigidImpact.prepare()
        notificationFeedback.prepare()
    }
    
    private func setupAudioEngine() {
        // 1. Attach SFX Nodes
        for _ in 0..<sfxNodeCount {
            let node = AVAudioPlayerNode()
            audioEngine.attach(node)
            audioEngine.connect(node, to: audioEngine.mainMixerNode, format: audioFormat)
            sfxPlayerNodes.append(node)
        }
        
        // 2. Attach Dedicated Looping BGM Node
        audioEngine.attach(bgmPlayerNode)
        audioEngine.connect(bgmPlayerNode, to: audioEngine.mainMixerNode, format: audioFormat)
        bgmPlayerNode.volume = 0.5 // Ambient level
        
        do {
            try audioEngine.start()
            for player in sfxPlayerNodes {
                player.play()
            }
        } catch {
            print("Audio Engine Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Synthesis & Buffer Pre-rendering
    private func preRenderBuffers() {
        // Catch Tones
        let standardScale: [Double] = [329.63, 392.00, 440.00, 523.25, 659.25, 783.99, 880.00]
        for freq in standardScale {
            if let buf = renderPluck(freq: freq, duration: 0.08, decay: 24.0) {
                catchBuffers.append(buf)
            }
        }
        
        // Fever Gold Tones
        let goldNotes: [Double] = [
            440.00, 523.25, 587.33, 659.25, 783.99,
            880.00, 987.77, 1046.50, 1174.66, 1318.51
        ]
        for freq in goldNotes {
            if let buf = renderGoldChime(freq: freq, duration: 0.09) {
                goldPoolBuffers.append(buf)
            }
        }
        
        edgeBuffer = renderDualTone(f1: 587.33, f2: 880.00, duration: 0.10, decay: 22.0)
        hazardBuffer = renderPluck(freq: 100.0, duration: 0.20, decay: 12.0, isHazard: true)
        powerupBuffer = renderDualTone(f1: 440.00, f2: 659.25, duration: 0.12, decay: 18.0)
        fanfareBuffer = renderChord(freqs: [440.00, 554.37, 659.25, 880.00], duration: 0.24)
        
        // UI Button Click (Snappy High Arcade Beep)
        buttonClickBuffer = renderButtonClick()
        
        // Game Over Synth Decent (Dissonant Drone)
        gameOverBuffer = renderGameOverSound()
        
        // Continuous Ambient Synthwave Loop (~6.0s seamless loop)
        bgmLoopBuffer = renderAmbientSynthwaveLoop()
    }
    
    // MARK: - Background Music Lifecycle
    private func startAmbientBGM() {
        guard let buffer = bgmLoopBuffer else { return }
        
        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
            } catch {
                print("Audio Engine Restart Error: \(error.localizedDescription)")
            }
        }
        
        bgmPlayerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        bgmPlayerNode.play()
        isBgmPlaying = true
    }
    
    // MARK: - Public Playback Triggers
    func playButtonClick() {
        if let buf = buttonClickBuffer {
            play(buffer: buf)
        }
        lightImpact.impactOccurred(intensity: 0.6)
    }
    
    func playGameOver() {
        if let buf = gameOverBuffer {
            play(buffer: buf)
        }
        heavyImpact.impactOccurred(intensity: 1.0)
    }
    
    func playCatch(combo: Int) {
        let index = (combo - 1) % max(1, catchBuffers.count)
        if index < catchBuffers.count {
            play(buffer: catchBuffers[index])
        }
        lightImpact.impactOccurred(intensity: 0.75)
    }
    
    func playGoldCatch() {
        guard !goldPoolBuffers.isEmpty else { return }
        var nextIndex = Int.random(in: 0..<goldPoolBuffers.count)
        if nextIndex == lastGoldNoteIndex {
            nextIndex = (nextIndex + 1) % goldPoolBuffers.count
        }
        lastGoldNoteIndex = nextIndex
        play(buffer: goldPoolBuffers[nextIndex])
        rigidImpact.impactOccurred(intensity: 0.85)
    }
    
    func resetFeverStreak() {
        lastGoldNoteIndex = -1
    }
    
    func playEdgeCatch() {
        if let buf = edgeBuffer { play(buffer: buf) }
        mediumImpact.impactOccurred(intensity: 1.0)
    }
    
    func playHazard() {
        if let buf = hazardBuffer { play(buffer: buf) }
        heavyImpact.impactOccurred(intensity: 1.0)
    }
    
    func playPowerup() {
        if let buf = powerupBuffer { play(buffer: buf) }
        notificationFeedback.notificationOccurred(.success)
    }
    
    func playPulseRushFanfare() {
        if let buf = fanfareBuffer { play(buffer: buf) }
        notificationFeedback.notificationOccurred(.warning)
    }
    
    func playNewRecordFanfare() {
        notificationFeedback.notificationOccurred(.success)
        let recordChord: [Double] = [523.25, 659.25, 783.99, 1046.50, 1318.51]
        for (index, _) in recordChord.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.04) { [weak self] in
                self?.playCatch(combo: index + 4)
            }
        }
    }
    
    private func play(buffer: AVAudioPCMBuffer) {
        let player = sfxPlayerNodes[sfxIndex]
        sfxIndex = (sfxIndex + 1) % sfxNodeCount
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
    }
    
    // MARK: - Procedural Synth Generators
    
    /// Renders a seamless 6.4s Synthwave ambient track with bass drone and cycling arpeggios
    private func renderAmbientSynthwaveLoop() -> AVAudioPCMBuffer? {
        let sampleRate = audioFormat.sampleRate
        let duration: Double = 6.4
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        
        let left = buffer.floatChannelData?[0]
        let right = buffer.floatChannelData?[1]
        
        let arpeggioNotes: [Double] = [220.0, 261.63, 329.63, 392.0, 440.0, 392.0, 329.63, 261.63]
        let stepDuration = 0.20
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            
            // 1. Deep Sub Bass Drone (A1: 55Hz & E2: 82.4Hz)
            let bass = (sin(2.0 * .pi * 55.0 * t) + 0.5 * sin(2.0 * .pi * 82.4 * t)) * 0.28
            
            // 2. Cosmic Pulsing Pad (Warm Low-Pass Sine Wave)
            let padLFO = 0.5 + 0.5 * sin(2.0 * .pi * 0.3125 * t)
            let pad = sin(2.0 * .pi * 164.81 * t) * padLFO * 0.15
            
            // 3. Synthwave Cycling Arp
            let noteIdx = Int(t / stepDuration) % arpeggioNotes.count
            let noteTime = t.truncatingRemainder(dividingBy: stepDuration)
            let noteEnv = exp(-noteTime * 14.0)
            let arpFreq = arpeggioNotes[noteIdx]
            let arp = sin(2.0 * .pi * arpFreq * noteTime) * noteEnv * 0.18
            
            let sampleL = Float((bass + pad * 0.9 + arp * 0.8) * 0.45)
            let sampleR = Float((bass + pad * 1.1 + arp * 1.2) * 0.45)
            
            left?[frame] = sampleL
            right?[frame] = sampleR
        }
        return buffer
    }
    
    /// Renders a crisp UI Button Click sound
    private func renderButtonClick() -> AVAudioPCMBuffer? {
        let sampleRate = audioFormat.sampleRate
        let duration: Double = 0.05
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        
        let left = buffer.floatChannelData?[0]
        let right = buffer.floatChannelData?[1]
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let env = exp(-t * 80.0)
            let freq = 1200.0 - (t * 6000.0)
            let sample = Float(sin(2.0 * .pi * max(100.0, freq) * t) * env * 0.25)
            left?[frame] = sample
            right?[frame] = sample
        }
        return buffer
    }
    
    /// Renders the signature "Tape-Stop & Reverse Warp" game-over sound with punchy arcade character
    private func renderGameOverSound() -> AVAudioPCMBuffer? {
        let sampleRate = audioFormat.sampleRate
        let duration: Double = 0.75
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        
        let left = buffer.floatChannelData?[0]
        let right = buffer.floatChannelData?[1]
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            
            // 1. Analog Tape-Stop Pitch Dive (Mechanical brake feel)
            var tapeStop: Double = 0.0
            if t < 0.28 {
                let localT = t / 0.28
                let freq = 880.0 * pow(1.0 - localT, 2.8) + 60.0
                let env = 1.0 - (localT * 0.7)
                let sine = sin(2.0 * .pi * freq * t)
                let grit = (sine > 0 ? 1.0 : -1.0) * 0.20
                tapeStop = (sine * 0.75 + grit) * env * 0.38
            }
            
            // 2. Reverse Synth Warp / Rewind Whoosh (0.15s - 0.55s)
            var reverseWarp: Double = 0.0
            if t >= 0.15 && t < 0.55 {
                let localT = (t - 0.15) / 0.40
                let warpFreq = 120.0 + pow(localT, 2.2) * 980.0
                let env = sin(.pi * localT)
                let s1 = sin(2.0 * .pi * warpFreq * t)
                let s2 = sin(2.0 * .pi * (warpFreq * 1.5) * t) * 0.35
                reverseWarp = (s1 + s2) * env * 0.32
            }
            
            // 3. Final Low Impact Thump (0.35s - 0.75s)
            var subImpact: Double = 0.0
            if t >= 0.35 {
                let localT = t - 0.35
                let env = exp(-localT * 12.0)
                let freq = max(35.0, 160.0 - (localT * 320.0))
                subImpact = sin(2.0 * .pi * freq * localT) * env * 0.42
            }
            
            // Master volume balanced so it punches through without clipping
            let mixedSample = Float((tapeStop + reverseWarp + subImpact) * 0.1)
            
            left?[frame] = mixedSample
            right?[frame] = mixedSample
        }
        return buffer
    }
    
    private func renderGoldChime(freq: Double, duration: Double) -> AVAudioPCMBuffer? {
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let left = buffer.floatChannelData?[0]
        let right = buffer.floatChannelData?[1]
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let env = exp(-t * 22.0)
            let s1 = sin(2.0 * .pi * freq * t)
            let s2 = sin(2.0 * .pi * (freq * 0.5) * t) * 0.25
            let s3 = sin(2.0 * .pi * (freq * 2.0) * t) * 0.20
            let sample = Float((s1 + s2 + s3) * 0.65 * env * 0.24)
            left?[frame] = sample
            right?[frame] = sample
        }
        return buffer
    }
    
    private func renderPluck(freq: Double, duration: Double, decay: Double, isHazard: Bool = false) -> AVAudioPCMBuffer? {
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let left = buffer.floatChannelData?[0]
        let right = buffer.floatChannelData?[1]
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let env = exp(-t * decay)
            let sample = Float(sin(2.0 * .pi * freq * t) * env * (isHazard ? 0.35 : 0.22))
            left?[frame] = sample
            right?[frame] = sample
        }
        return buffer
    }
    
    private func renderDualTone(f1: Double, f2: Double, duration: Double, decay: Double) -> AVAudioPCMBuffer? {
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let left = buffer.floatChannelData?[0]
        let right = buffer.floatChannelData?[1]
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let env = exp(-t * decay)
            let sample = Float((sin(2.0 * .pi * f1 * t) + sin(2.0 * .pi * f2 * t) * 0.6) * 0.5 * env * 0.22)
            left?[frame] = sample
            right?[frame] = sample
        }
        return buffer
    }
    
    private func renderChord(freqs: [Double], duration: Double) -> AVAudioPCMBuffer? {
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let left = buffer.floatChannelData?[0]
        let right = buffer.floatChannelData?[1]
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let env = exp(-t * 8.0)
            var sum: Double = 0
            for f in freqs { sum += sin(2.0 * .pi * f * t) }
            let sample = Float((sum / Double(freqs.count)) * env * 0.25)
            left?[frame] = sample
            right?[frame] = sample
        }
        return buffer
    }
}

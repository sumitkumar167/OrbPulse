import AVFoundation
import AudioToolbox
import CoreHaptics

final class FeedbackManager {
    static let shared = FeedbackManager()
    
    private var hapticEngine: CHHapticEngine?
    private var audioEngine = AVAudioEngine()
    private var playerNodes: [AVAudioPlayerNode] = []
    private var nodeIndex = 0
    private let nodeCount = 14
    
    private let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)!
    
    private var catchBuffers: [AVAudioPCMBuffer] = []
    private var goldPoolBuffers: [AVAudioPCMBuffer] = []
    private var edgeBuffer: AVAudioPCMBuffer?
    private var hazardBuffer: AVAudioPCMBuffer?
    private var powerupBuffer: AVAudioPCMBuffer?
    private var fanfareBuffer: AVAudioPCMBuffer?
    
    private var lastGoldNoteIndex = -1
    
    private init() {
        setupHaptics()
        setupAudioEngine()
        preRenderBuffers()
    }
    
    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {}
    }
    
    private func setupAudioEngine() {
        for _ in 0..<nodeCount {
            let node = AVAudioPlayerNode()
            audioEngine.attach(node)
            audioEngine.connect(node, to: audioEngine.mainMixerNode, format: audioFormat)
            playerNodes.append(node)
        }
        
        do {
            try audioEngine.start()
        } catch {}
    }
    
    // MARK: - Pre-Render Clean Arcade Tones
    private func preRenderBuffers() {
        // Standard Catch Progression (Clean C-Major Pentatonic)
        let standardScale: [Double] = [329.63, 392.00, 440.00, 523.25, 659.25, 783.99, 880.00]
        for freq in standardScale {
            if let buf = renderPluck(freq: freq, duration: 0.08, decay: 24.0) {
                catchBuffers.append(buf)
            }
        }
        
        // Fever Gold Organic Pool: 10 shimmering harmonic frequencies
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
    }
    
    func playCatch(combo: Int) {
        let index = (combo - 1) % max(1, catchBuffers.count)
        if index < catchBuffers.count {
            play(buffer: catchBuffers[index])
        }
        triggerHaptic(intensity: 0.6, sharpness: 0.7)
    }
    
    // Non-repeating randomized gold chime
    func playGoldCatch() {
        guard !goldPoolBuffers.isEmpty else { return }
        
        var nextIndex = Int.random(in: 0..<goldPoolBuffers.count)
        if nextIndex == lastGoldNoteIndex {
            nextIndex = (nextIndex + 1) % goldPoolBuffers.count
        }
        lastGoldNoteIndex = nextIndex
        
        play(buffer: goldPoolBuffers[nextIndex])
        triggerHaptic(intensity: 0.8, sharpness: 0.8)
    }
    
    func resetFeverStreak() {
        lastGoldNoteIndex = -1
    }
    
    func playEdgeCatch() {
        if let buf = edgeBuffer { play(buffer: buf) }
        triggerHaptic(intensity: 0.9, sharpness: 0.95)
    }
    
    func playHazard() {
        if let buf = hazardBuffer { play(buffer: buf) }
        triggerHaptic(intensity: 1.0, sharpness: 0.3)
    }
    
    func playPowerup() {
        if let buf = powerupBuffer { play(buffer: buf) }
        triggerHaptic(intensity: 0.8, sharpness: 0.8)
    }
    
    func playPulseRushFanfare() {
        if let buf = fanfareBuffer { play(buffer: buf) }
        triggerHaptic(intensity: 1.0, sharpness: 0.9)
    }
    
    func playNewRecordFanfare() {
        triggerHaptic(intensity: 1.0, sharpness: 1.0)
        let recordChord: [Double] = [523.25, 659.25, 783.99, 1046.50, 1318.51]
        for (index, freq) in recordChord.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.04) { [weak self] in
                self?.playCatch(combo: index + 4)
            }
        }
    }
    
    private func play(buffer: AVAudioPCMBuffer) {
        let player = playerNodes[nodeIndex]
        nodeIndex = (nodeIndex + 1) % nodeCount
        
        if player.isPlaying {
            player.stop()
        }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }
    
    private func triggerHaptic(intensity: Float, sharpness: Float) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        let i = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let s = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [i, s], relativeTime: 0)
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {}
    }
    
    // MARK: - Synthesis Generators
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
            
            // Fundamental + Warm Sub Harmonic + Sparkle
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

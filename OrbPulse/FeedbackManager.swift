import AVFoundation
import AudioToolbox
import CoreHaptics

final class FeedbackManager {
    static let shared = FeedbackManager()
    
    private var hapticEngine: CHHapticEngine?
    private var audioEngine = AVAudioEngine()
    private var playerNodes: [AVAudioPlayerNode] = []
    private var nodeIndex = 0
    private let nodeCount = 8
    
    private let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)!
    
    // Pre-rendered cached buffers
    private var catchBuffers: [AVAudioPCMBuffer] = []
    private var goldBuffer: AVAudioPCMBuffer?
    private var edgeBuffer: AVAudioPCMBuffer?
    private var hazardBuffer: AVAudioPCMBuffer?
    private var powerupBuffer: AVAudioPCMBuffer?
    private var fanfareBuffer: AVAudioPCMBuffer?
    
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
    
    // MARK: - Pre-Render All Audio Buffers at Startup
    private func preRenderBuffers() {
        // Pentatonic Scale: C4, D4, E4, G4, A4, C5, D5, E5
        let scale: [Double] = [261.63, 293.66, 329.63, 392.00, 440.00, 523.25, 587.33, 659.25]
        
        for freq in scale {
            if let buf = renderTone(freq: freq, duration: 0.08, decay: 22.0) {
                catchBuffers.append(buf)
            }
        }
        
        goldBuffer = renderDualTone(f1: 392.00, f2: 587.33, duration: 0.09, decay: 20.0)
        edgeBuffer = renderDualTone(f1: 523.25, f2: 783.99, duration: 0.10, decay: 24.0)
        hazardBuffer = renderTone(freq: 95.0, duration: 0.18, decay: 10.0, isHazard: true)
        powerupBuffer = renderDualTone(f1: 440.00, f2: 659.25, duration: 0.12, decay: 18.0)
        fanfareBuffer = renderChord(freqs: [392.00, 493.88, 587.33, 783.99], duration: 0.25)
    }
    
    // MARK: - Playback
    func playCatch(combo: Int) {
        let index = (combo - 1) % max(1, catchBuffers.count)
        if index < catchBuffers.count {
            play(buffer: catchBuffers[index])
        }
        triggerHaptic(intensity: 0.6, sharpness: 0.7)
    }
    
    func playGoldCatch() {
        if let buf = goldBuffer { play(buffer: buf) }
        triggerHaptic(intensity: 0.7, sharpness: 0.6)
    }
    
    func playEdgeCatch() {
        if let buf = edgeBuffer { play(buffer: buf) }
        triggerHaptic(intensity: 0.85, sharpness: 0.9)
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
    
    // MARK: - Buffer Synthesis Generators
    private func renderTone(freq: Double, duration: Double, decay: Double, isHazard: Bool = false) -> AVAudioPCMBuffer? {
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
            let sample = Float((sin(2.0 * .pi * f1 * t) + sin(2.0 * .pi * f2 * t) * 0.7) * 0.5 * env * 0.22)
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

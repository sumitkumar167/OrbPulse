//
//  FeedbackManager.swift
//  OrbPulse
//
//  Created by Sumit Kumar on 16/08/26.
//


import AVFoundation
import CoreHaptics

final class FeedbackManager {
    static let shared = FeedbackManager()
    
    private var hapticEngine: CHHapticEngine?
    private var audioEngine = AVAudioEngine()
    private var audioPlayer = AVAudioPlayerNode()
    private let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)!
    
    // C-Major Pentatonic Frequencies (Hz) across two octaves
    // C5, D5, E5, G5, A5, C6, D6, E6, G6, A6, C7
    private let pentatonicScale: [Double] = [
        523.25, 587.33, 659.25, 783.99, 880.00,
        1046.50, 1174.66, 1318.51, 1567.98, 1760.00, 2093.00
    ]
    
    private init() {
        setupHaptics()
        setupAudio()
    }
    
    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptics Init Error: \(error.localizedDescription)")
        }
    }
    
    private func setupAudio() {
        audioEngine.attach(audioPlayer)
        audioEngine.connect(audioPlayer, to: audioEngine.mainMixerNode, format: audioFormat)
        do {
            try audioEngine.start()
        } catch {
            print("Audio Engine Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Musical Catch
    func playCatch(combo: Int) {
        // Map combo streak to progressive pentatonic notes
        let noteIndex = min(combo, pentatonicScale.count - 1)
        let frequency = pentatonicScale[max(0, noteIndex)]
        
        let intensity = min(1.0, 0.6 + Float(combo) * 0.02)
        let sharpness = min(1.0, 0.7 + Float(combo) * 0.02)
        triggerHaptic(intensity: intensity, sharpness: sharpness)
        
        playTone(frequency: frequency, duration: 0.09, decayFactor: 0.8)
    }
    
    func playEdgeCatch() {
        triggerHaptic(intensity: 0.9, sharpness: 1.0)
        // High resonance bell chime
        playTone(frequency: 1318.51, duration: 0.14, decayFactor: 0.6)
    }
    
    func playHazard() {
        triggerHaptic(intensity: 1.0, sharpness: 0.3)
        // Low dissonance crunch
        playTone(frequency: 110.0, duration: 0.28, decayFactor: 0.4)
    }
    
    func playPowerup() {
        triggerHaptic(intensity: 0.9, sharpness: 0.8)
        // High ascending double chime
        playTone(frequency: 1046.50, duration: 0.08, decayFactor: 0.9)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            self?.playTone(frequency: 1567.98, duration: 0.12, decayFactor: 0.8)
        }
    }
    
    func playPulseRushFanfare() {
        triggerHaptic(intensity: 1.0, sharpness: 0.9)
        let triad: [Double] = [523.25, 659.25, 783.99, 1046.50]
        for (index, freq) in triad.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.06) { [weak self] in
                self?.playTone(frequency: freq, duration: 0.15, decayFactor: 0.85)
            }
        }
    }
    
    private func triggerHaptic(intensity: Float, sharpness: Float) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensityParam, sharpnessParam], relativeTime: 0)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Haptic trigger failed: \(error.localizedDescription)")
        }
    }
    
    private func playTone(frequency: Double, duration: Double, decayFactor: Double = 0.8) {
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        
        let leftChannel = buffer.floatChannelData?[0]
        let rightChannel = buffer.floatChannelData?[1]
        let angularFrequency = 2.0 * .pi * frequency
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            // Exponential envelope for clean synthesizer bell strike
            let progress = Double(frame) / Double(frameCount)
            let envelope = pow(1.0 - progress, decayFactor * 2.5)
            let sample = Float(sin(angularFrequency * time) * envelope * 0.28)
            leftChannel?[frame] = sample
            rightChannel?[frame] = sample
        }
        
        audioPlayer.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        if !audioPlayer.isPlaying {
            audioPlayer.play()
        }
    }
}

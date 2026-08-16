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
    
    // Warm, euphoric C-Major Pentatonic Scale (Hz): C4 -> A5
    private let pentatonicScale: [Double] = [
        261.63, 293.66, 329.63, 392.00, 440.00,
        523.25, 587.33, 659.25, 783.99, 880.00
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
            print("Haptics Error: \(error.localizedDescription)")
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
    
    func playCatch(combo: Int) {
        let noteIndex = (combo - 1) % pentatonicScale.count
        let frequency = pentatonicScale[noteIndex]
        
        let intensity = min(1.0, 0.6 + Float(combo % 10) * 0.04)
        let sharpness = min(0.85, 0.5 + Float(combo % 10) * 0.03)
        triggerHaptic(intensity: intensity, sharpness: sharpness)
        
        playWarmTone(frequency: frequency, duration: 0.12)
    }
    
    func playGoldCatch() {
        triggerHaptic(intensity: 0.85, sharpness: 0.7)
        // Harmonized euphoric golden chime (E5 + C6)
        playHarmonizedTone(baseFreq: 659.25, intervalFreq: 1046.50, duration: 0.14)
    }
    
    func playEdgeCatch() {
        triggerHaptic(intensity: 0.9, sharpness: 1.0)
        playWarmTone(frequency: 783.99, duration: 0.16)
    }
    
    func playHazard() {
        triggerHaptic(intensity: 1.0, sharpness: 0.3)
        playWarmTone(frequency: 110.0, duration: 0.28, isHazard: true)
    }
    
    func playPowerup() {
        triggerHaptic(intensity: 0.9, sharpness: 0.8)
        playHarmonizedTone(baseFreq: 523.25, intervalFreq: 783.99, duration: 0.18)
    }
    
    func playPulseRushFanfare() {
        triggerHaptic(intensity: 1.0, sharpness: 0.9)
        let chord: [Double] = [261.63, 329.63, 392.00, 523.25, 659.25]
        for (index, freq) in chord.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) { [weak self] in
                self?.playWarmTone(frequency: freq, duration: 0.20)
            }
        }
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
    
    // Rich harmonic synthesis with low-pass roll-off (eliminates harsh high beeps)
    private func playWarmTone(frequency: Double, duration: Double, isHazard: Bool = false) {
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        
        let left = buffer.floatChannelData?[0]
        let right = buffer.floatChannelData?[1]
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let envelope = pow(1.0 - (Double(frame) / Double(frameCount)), 1.8)
            
            // Dual oscillator (fundamental + warm octave overtone)
            let fundamental = sin(2.0 * .pi * frequency * time)
            let overtone = sin(2.0 * .pi * (frequency * 0.5) * time) * 0.3
            let signal = isHazard ? Float(fundamental * envelope * 0.35) : Float((fundamental + overtone) * envelope * 0.22)
            
            left?[frame] = signal
            right?[frame] = signal
        }
        
        audioPlayer.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        if !audioPlayer.isPlaying { audioPlayer.play() }
    }
    
    private func playHarmonizedTone(baseFreq: Double, intervalFreq: Double, duration: Double) {
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        
        let left = buffer.floatChannelData?[0]
        let right = buffer.floatChannelData?[1]
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let envelope = pow(1.0 - (Double(frame) / Double(frameCount)), 1.5)
            let sample = Float((sin(2.0 * .pi * baseFreq * time) + sin(2.0 * .pi * intervalFreq * time)) * 0.5 * envelope * 0.25)
            left?[frame] = sample
            right?[frame] = sample
        }
        
        audioPlayer.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        if !audioPlayer.isPlaying { audioPlayer.play() }
    }
}

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
    
    func playCatch(pitchShift: Double = 1.0) {
        triggerHaptic(intensity: 0.7, sharpness: 0.9)
        playTone(frequency: 600.0 * pitchShift, duration: 0.08)
    }
    
    func playHazard() {
        triggerHaptic(intensity: 1.0, sharpness: 0.3)
        playTone(frequency: 140.0, duration: 0.25)
    }
    
    func playPowerup() {
        triggerHaptic(intensity: 0.9, sharpness: 0.8)
        playTone(frequency: 1100.0, duration: 0.16)
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
    
    private func playTone(frequency: Double, duration: Double) {
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        
        let leftChannel = buffer.floatChannelData?[0]
        let rightChannel = buffer.floatChannelData?[1]
        let angularFrequency = 2.0 * .pi * frequency
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let envelope = 1.0 - (Double(frame) / Double(frameCount))
            let sample = Float(sin(angularFrequency * time) * envelope * 0.25)
            leftChannel?[frame] = sample
            rightChannel?[frame] = sample
        }
        
        audioPlayer.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        if !audioPlayer.isPlaying {
            audioPlayer.play()
        }
    }
}
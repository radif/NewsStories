//
//  WatchSpeechService.swift
//  NewsStoriesWatch Watch App
//
//  Created by Radif Sharafullin on 12/12/25.
//

import AVFoundation

// MARK: - Watch Speech Service

@Observable
final class WatchSpeechService: NSObject {
    static let shared = WatchSpeechService()

    private let synthesizer = AVSpeechSynthesizer()
    private(set) var isSpeaking = false

    static var isAvailable: Bool {
        // Check if TTS is available on watchOS
        return AVSpeechSynthesisVoice.speechVoices().count > 0
    }

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        // Use compact voice for watch if available
        if let voice = AVSpeechSynthesisVoice(language: Locale.current.language.languageCode?.identifier ?? "en-US") {
            utterance.voice = voice
        }

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    func toggle(_ text: String) {
        if isSpeaking {
            stop()
        } else {
            speak(text)
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension WatchSpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}

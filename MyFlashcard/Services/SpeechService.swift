import Foundation
import AVFoundation

/// Speech Service - American English pronunciation
@MainActor
class SpeechService: NSObject, ObservableObject, @preconcurrency AVSpeechSynthesizerDelegate {
    static let shared = SpeechService()
    
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    
    private let americanVoice = "en-US"
    
    override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio Session Error: \(error.localizedDescription)")
        }
    }
    
    func speak(_ text: String, rate: Float = 0.5) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: americanVoice)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    func speakSlow(_ text: String) {
        speak(text, rate: 0.3)
    }

    /// Lightweight pronunciation hint for learners when IPA is missing.
    func pronunciationHint(for text: String) -> String {
        let normalized = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return "" }

        var hint = normalized
            .replacingOccurrences(of: "tion", with: "shun")
            .replacingOccurrences(of: "ough", with: "off/oh/uh")
            .replacingOccurrences(of: "th", with: "th")
            .replacingOccurrences(of: "ph", with: "f")
            .replacingOccurrences(of: "qu", with: "kw")

        hint = hint.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return hint
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = true }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }
}

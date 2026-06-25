import Foundation

/// Drives the opt-in "say Halo while backgrounded" experience.
///
/// Owns a continuous `SpeechRecognizer`, watches each final transcript for the "Halo" wake word,
/// runs the matching command, and confirms it with a local notification (since the UI may not be
/// visible). Note: iOS cannot listen once the app is *terminated* — this works while the app is
/// merely backgrounded, and keeps the mic indicator on. Gated by the Settings toggle.
@MainActor
@Observable
final class HaloListener {
    static let shared = HaloListener()

    private let recognizer = SpeechRecognizer()
    private(set) var isRunning = false
    private var pausedForForegroundMic = false

    private init() {
        recognizer.keepAlive = true
        recognizer.onFinalTranscript = { [weak self] text in
            Task { @MainActor in await self?.handle(text) }
        }
    }

    /// Starts continuous listening (requesting permission if needed).
    func enable() async {
        guard !isRunning else { return }
        guard await recognizer.requestAuthorization() else { return }
        recognizer.keepAlive = true
        recognizer.start()
        isRunning = true
    }

    func disable() {
        guard isRunning else { return }
        recognizer.stop()
        isRunning = false
    }

    /// Releases the mic so the manual `VoiceModeView` can use it.
    func pauseForForegroundMic() {
        guard isRunning else { return }
        recognizer.stop()
        pausedForForegroundMic = true
    }

    func resumeAfterForegroundMic() {
        guard pausedForForegroundMic else { return }
        pausedForForegroundMic = false
        recognizer.keepAlive = true
        recognizer.start()
    }

    private func handle(_ text: String) async {
        // Only act on utterances that actually start with the wake word.
        guard VoiceCommandRouter.startsWithWakeWord(text) else { return }
        let outcome = await VoiceCommandRouter().handle(text)
        guard outcome.action != .unknown else { return }
        await NotificationService.shared.notifyVoiceResult(outcome.message)
    }
}

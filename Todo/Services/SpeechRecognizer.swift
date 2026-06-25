import Foundation
import Speech
import AVFoundation

/// On-device speech recognition for the in-app "Halo" voice mode.
///
/// Two modes:
/// - one-shot (default): stops after the first final result (used by `VoiceModeView`).
/// - `keepAlive`: rotates to a fresh recognition segment after each result without tearing
///   down the audio engine, so it can keep listening (incl. in the background) for `HaloListener`.
///
/// `@unchecked Sendable` because audio/recognition callbacks fire off the main thread;
/// all observable mutations are hopped back to the main queue.
@Observable
final class SpeechRecognizer: @unchecked Sendable {
    var transcript: String = ""
    var isListening: Bool = false
    var authorized: Bool = true
    var keepAlive: Bool = false
    /// Called on the main queue with each final segment's text.
    var onFinalTranscript: ((String) -> Void)?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    /// Requests speech + microphone permission. Returns whether both were granted.
    func requestAuthorization() async -> Bool {
        let speechOK = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
        let micOK = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            AVAudioApplication.requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
        let ok = speechOK && micOK
        DispatchQueue.main.async { self.authorized = ok }
        return ok
    }

    func start() {
        guard !audioEngine.isRunning else { return }
        configureSession()

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            return
        }
        isListening = true
        beginSegment()
    }

    func stop() {
        keepAlive = false
        finishAudio()
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        // Continuous mode uses playAndRecord + mixWithOthers so the session survives backgrounding.
        let category: AVAudioSession.Category = keepAlive ? .playAndRecord : .record
        let options: AVAudioSession.CategoryOptions = keepAlive
            ? [.mixWithOthers, .duckOthers, .defaultToSpeaker]
            : [.duckOthers]
        try? session.setCategory(category, mode: .measurement, options: options)
        try? session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func beginSegment() {
        task?.cancel()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer?.supportsOnDeviceRecognition == true {
            request.requiresOnDeviceRecognition = true
        }
        self.request = request
        DispatchQueue.main.async { self.transcript = "" }

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async { self.transcript = text }
            }
            let done = error != nil || (result?.isFinal ?? false)
            guard done else { return }
            let finalText = result?.bestTranscription.formattedString ?? ""
            DispatchQueue.main.async {
                if !finalText.isEmpty { self.onFinalTranscript?(finalText) }
                if self.keepAlive && self.audioEngine.isRunning {
                    self.request?.endAudio()
                    self.beginSegment()   // rotate; keep the engine + session running
                } else {
                    self.finishAudio()
                }
            }
        }
    }

    private func finishAudio() {
        task?.cancel()
        task = nil
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        request = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        DispatchQueue.main.async { self.isListening = false }
    }
}

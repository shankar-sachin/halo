import SwiftUI

/// The in-app "Halo" voice experience: listens on device, shows the live transcript,
/// then performs the recognized command and confirms it.
struct VoiceModeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var recognizer = SpeechRecognizer()

    private enum Phase: Equatable { case listening, processing, result, denied }
    @State private var phase: Phase = .listening
    @State private var resultMessage = ""
    @State private var resultAction: VoiceCommandRouter.Action = .unknown
    @State private var pulse = false
    @State private var showGuide = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()
                orb
                content
                Spacer()
                controls
            }
            .padding(28)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.backdrop(.purple))
            .navigationTitle("Halo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showGuide = true } label: { Image(systemName: "info.circle") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { recognizer.stop(); dismiss() }
                }
            }
            .sheet(isPresented: $showGuide) { VoiceGuideView() }
        }
        .task {
            HaloListener.shared.pauseForForegroundMic()
            await begin()
        }
        .onDisappear {
            recognizer.stop()
            HaloListener.shared.resumeAfterForegroundMic()
        }
        .onChange(of: recognizer.isListening) { _, listening in
            if !listening, phase == .listening { Task { await process() } }
        }
    }

    // MARK: - Pieces

    private var orb: some View {
        ZStack {
            Circle()
                .fill(.purple.opacity(0.25))
                .frame(width: 180, height: 180)
                .scaleEffect(pulse && phase == .listening ? 1.15 : 0.9)
                .blur(radius: 12)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)

            Image(systemName: phase == .result ? resultAction.systemImage
                  : (phase == .denied ? "mic.slash.fill" : "mic.fill"))
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(.purple)
                .frame(width: 150, height: 150)
                .glassEffect(.regular.tint(.purple.opacity(0.18)), in: .circle)
                .contentTransition(.symbolEffect(.replace))
        }
        .onAppear { pulse = true }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .listening:
            VStack(spacing: 8) {
                Text(recognizer.transcript.isEmpty ? "Listening…" : recognizer.transcript)
                    .font(.title3.weight(.medium))
                    .multilineTextAlignment(.center)
                    .animation(.default, value: recognizer.transcript)
                Text("Try “Halo, add a to-do to call mom at 6pm.”")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(minHeight: 80)
        case .processing:
            ProgressView("Working on it…").frame(minHeight: 80)
        case .result:
            GlassCard(tint: .purple) {
                Text(resultMessage)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .frame(minHeight: 80)
        case .denied:
            Text("Halo needs microphone and speech access. Enable them in Settings to talk to the app.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(minHeight: 80)
        }
    }

    @ViewBuilder
    private var controls: some View {
        switch phase {
        case .listening:
            Button {
                recognizer.stop() // triggers process() via onChange
            } label: {
                Label("Stop & run", systemImage: "stop.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(.purple)
        case .result, .denied:
            Button {
                Task { await begin() }
            } label: {
                Label("Listen again", systemImage: "mic.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(.purple)
        case .processing:
            EmptyView()
        }
    }

    // MARK: - Flow

    private func begin() async {
        resultMessage = ""
        phase = .listening
        let ok = await recognizer.requestAuthorization()
        guard ok else { phase = .denied; return }
        recognizer.start()
    }

    private func process() async {
        let text = recognizer.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            resultAction = .unknown
            resultMessage = "I didn't catch that. Tap Listen again."
            phase = .result
            return
        }
        phase = .processing
        let outcome = await VoiceCommandRouter().handle(text)
        resultAction = outcome.action
        resultMessage = outcome.message
        phase = .result
    }
}

#Preview {
    VoiceModeView()
        .modelContainer(DataController.shared.container)
}

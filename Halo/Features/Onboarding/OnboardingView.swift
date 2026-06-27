import SwiftUI

/// First-launch walkthrough: introduces the "Hey Siri, tell Halo …" idea, sets up voice
/// permissions, and showcases commands — all in animated Liquid Glass.
struct OnboardingView: View {
    @AppStorage(SettingsKey.hasOnboarded, store: .shared) private var hasOnboarded = false
    @State private var page = 0

    private let lastPage = 4

    var body: some View {
        ZStack {
            AnimatedGlassBackground()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    WelcomePage().tag(0)
                    BigIdeaPage().tag(1)
                    DietPreferencesPage().tag(2)
                    VoiceSetupPage().tag(3)
                    CommandsPage().tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(.smooth, value: page)

                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
    }

    private var controls: some View {
        HStack {
            if page > 0 {
                Button("Back") { withAnimation { page -= 1 } }
                    .tint(.secondary)
            }
            Spacer()
            Button {
                if page < lastPage {
                    withAnimation { page += 1 }
                } else {
                    withAnimation { hasOnboarded = true }
                }
            } label: {
                Text(page < lastPage ? "Continue" : "Start using Halo")
                    .font(.headline)
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.glassProminent)
            .tint(.purple)
        }
    }
}

// MARK: - Animated background

private struct AnimatedGlassBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), .purple.opacity(0.18), .blue.opacity(0.12)],
                startPoint: .top, endPoint: .bottom
            )
            ForEach(0..<3) { i in
                Circle()
                    .fill([Color.purple, .blue, .pink][i].opacity(0.25))
                    .frame(width: 220, height: 220)
                    .blur(radius: 60)
                    .offset(
                        x: animate ? [80, -90, 40][i] : [-60, 70, -30][i],
                        y: animate ? [-120, 160, 280][i] : [120, -80, 320][i]
                    )
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animate)
        .onAppear { animate = true }
    }
}

// MARK: - Pulsing orb

private struct HaloOrb: View {
    var systemImage: String = "mic.fill"
    @State private var pulse = false

    var body: some View {
        ZStack {
            ForEach(0..<3) { ring in
                Circle()
                    .stroke(.purple.opacity(0.3), lineWidth: 2)
                    .frame(width: 140, height: 140)
                    .scaleEffect(pulse ? 1.6 : 0.8)
                    .opacity(pulse ? 0 : 0.6)
                    .animation(.easeOut(duration: 2.4).repeatForever(autoreverses: false)
                        .delay(Double(ring) * 0.8), value: pulse)
            }
            Image(systemName: systemImage)
                .font(.system(size: 50, weight: .semibold))
                .foregroundStyle(.purple)
                .frame(width: 130, height: 130)
                .glassEffect(.regular.tint(.purple.opacity(0.2)), in: .circle)
                .scaleEffect(pulse ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulse)
        }
        .onAppear { pulse = true }
    }
}

// MARK: - Pages

private struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            HaloOrb(systemImage: "sparkles")
            VStack(spacing: 10) {
                Text("Halo Lifestyle")
                    .font(.largeTitle.bold())
                Text("Control your lifestyle with your voice.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer(); Spacer()
        }
        .padding()
    }
}

private struct BigIdeaPage: View {
    private let examples = [
        "“…I ate my digestion pill.”",
        "“…I drank a cup of water.”",
        "“…add a to-do to call mom at 6.”",
        "“…log a 30 minute run.”",
        "“…I feel great today.”",
    ]
    @State private var index = 0

    var body: some View {
        VStack(spacing: 26) {
            Spacer()
            HaloOrb()
            VStack(spacing: 6) {
                Text("Just say")
                    .font(.title3).foregroundStyle(.secondary)
                Text("“Hey Siri, tell Halo…”")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
            }
            Text(examples[index])
                .font(.title3.weight(.medium))
                .foregroundStyle(.purple)
                .multilineTextAlignment(.center)
                .glassCapsule(tint: .purple)
                .id(index)
                .transition(.push(from: .bottom).combined(with: .opacity))
                .frame(height: 60)
            Text("…and Halo figures out the rest.")
                .font(.subheadline).foregroundStyle(.secondary)
            Spacer(); Spacer()
        }
        .padding()
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.2))
                withAnimation(.smooth) { index = (index + 1) % examples.count }
            }
        }
    }
}

private struct DietPreferencesPage: View {
    @AppStorage(SettingsKey.dietType, store: .shared) private var dietType: String = DietType.omnivore.rawValue
    @AppStorage(SettingsKey.dietLikes, store: .shared) private var likes: String = ""
    @AppStorage(SettingsKey.dietAllergies, store: .shared) private var allergies: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 12)
            HaloOrb(systemImage: "fork.knife")
            Text("Your food, your way")
                .font(.title.bold())
            Text("Halo tailors meal ideas to how you eat.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            ScrollView {
                VStack(spacing: 14) {
                    GlassCard(tint: Theme.dietTint) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Eating style").font(.subheadline.weight(.semibold))
                            DietTypeChips(rawValue: $dietType)
                        }
                    }
                    GlassCard(tint: Theme.dietTint) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Foods you love").font(.subheadline.weight(.semibold))
                            TextField("e.g. pasta, berries, salmon", text: $likes, axis: .vertical)
                                .lineLimit(1...3)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    GlassCard(tint: Theme.pillsTint) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Allergies").font(.subheadline.weight(.semibold))
                            AllergenChips(allergies: $allergies)
                        }
                    }
                }
                .padding(.horizontal)
            }
            Text("You can change all of this later in Settings.")
                .font(.footnote).foregroundStyle(.secondary)
            Spacer(minLength: 4)
        }
        .padding()
    }
}

private struct VoiceSetupPage: View {
    @AppStorage(SettingsKey.listenInBackground, store: .shared) private var listenInBackground = false
    @State private var voiceGranted = false
    @State private var requesting = false

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            HaloOrb(systemImage: voiceGranted ? "checkmark" : "waveform")
            Text("Set up your voice")
                .font(.title.bold())

            GlassCard(tint: .purple) {
                VStack(alignment: .leading, spacing: 14) {
                    Button {
                        Task { await enableVoice() }
                    } label: {
                        HStack {
                            Image(systemName: voiceGranted ? "checkmark.circle.fill" : "mic.fill")
                            Text(voiceGranted ? "Voice enabled" : "Enable microphone & speech")
                            Spacer()
                            if requesting { ProgressView() }
                        }
                        .font(.callout.weight(.medium))
                    }
                    .buttonStyle(.plain)
                    .disabled(voiceGranted || requesting)

                    Divider()

                    Toggle(isOn: $listenInBackground) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Listen in the background")
                            Text("Say “Halo, …” while the app is open or backgrounded.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .tint(.purple)
                }
            }
            .padding(.horizontal)

            Text("In-app and background modes catch your whole sentence in one breath. With Siri, say “Hey Siri, tell Halo” and it’ll ask what to do.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .padding()
    }

    private func enableVoice() async {
        requesting = true
        defer { requesting = false }
        let recognizer = SpeechRecognizer()
        voiceGranted = await recognizer.requestAuthorization()
        await NotificationService.shared.requestAuthorizationIfNeeded()
    }
}

private struct CommandsPage: View {
    private struct Cmd: Identifiable { let id = UUID(); let icon: String; let tint: Color; let text: String }
    private let commands: [Cmd] = [
        .init(icon: "checklist", tint: Theme.todoTint, text: "Add a to-do or set a reminder"),
        .init(icon: "fork.knife", tint: Theme.dietTint, text: "Log a meal — calories estimated for you"),
        .init(icon: "drop.fill", tint: Theme.waterTint, text: "Log water by the glass or bottle"),
        .init(icon: "pills.fill", tint: Theme.pillsTint, text: "Log a pill and what it’s for"),
        .init(icon: "figure.run", tint: Theme.workoutsTint, text: "Log workouts and habits"),
        .init(icon: "face.smiling", tint: Theme.moodTint, text: "Log your mood, jot a note"),
    ]
    @State private var shown = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("One phrase, everything")
                .font(.title.bold())
                .padding(.top, 40)
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(commands.enumerated()), id: \.element.id) { i, cmd in
                        GlassCard(tint: cmd.tint) {
                            HStack(spacing: 14) {
                                Image(systemName: cmd.icon)
                                    .font(.title2).foregroundStyle(cmd.tint).frame(width: 32)
                                Text(cmd.text).font(.callout)
                                Spacer()
                            }
                        }
                        .opacity(i < shown ? 1 : 0)
                        .offset(y: i < shown ? 0 : 20)
                    }
                }
                .padding(.horizontal)
            }
            Spacer()
        }
        .padding(.bottom)
        .task {
            for i in commands.indices {
                try? await Task.sleep(for: .seconds(0.12))
                withAnimation(.smooth) { shown = i + 1 }
            }
        }
    }
}

#Preview {
    OnboardingView()
}

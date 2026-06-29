import SwiftUI

/// One tracker a category hub links to.
struct TrackerLink: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let tint: Color
    let destination: AnyView

    init<Destination: View>(
        _ title: String,
        systemImage: String,
        tint: Color,
        @ViewBuilder destination: () -> Destination
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.destination = AnyView(destination())
    }
}

/// A category landing page: a glass-styled list of trackers that push into their detail views.
///
/// The hub owns the single `NavigationStack` for everything it pushes, so the tracker views it
/// links to must *not* wrap themselves in one (otherwise the bars nest). Renders as a tab on
/// iPhone and a sidebar entry on iPad via `RootTabView`'s `.sidebarAdaptable` style.
struct CategoryHubView: View {
    let title: String
    let tint: Color
    let links: [TrackerLink]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(links) { link in
                        NavigationLink {
                            link.destination
                        } label: {
                            row(link)
                                .contentShape(.rect(cornerRadius: 22))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .padding(.bottom, 30)
                .readableWidth()
            }
            .background(Theme.backdrop(tint))
            .navigationTitle(title)
        }
        .tint(tint)
    }

    private func row(_ link: TrackerLink) -> some View {
        GlassCard(tint: link.tint, interactive: true) {
            HStack(spacing: 14) {
                Image(systemName: link.systemImage)
                    .font(.title2)
                    .foregroundStyle(link.tint)
                    .frame(width: 32)
                Text(link.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

#Preview {
    CategoryHubView(title: "Nutrition", tint: Theme.nutritionTint, links: [
        TrackerLink("Diet", systemImage: "fork.knife", tint: Theme.dietTint) { DietView() },
        TrackerLink("Water", systemImage: "drop.fill", tint: Theme.waterTint) { WaterView() },
    ])
    .modelContainer(DataController.shared.container)
}

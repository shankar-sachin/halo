import ActivityKit
import WidgetKit
import SwiftUI

/// Lock Screen banner + Dynamic Island for an in-progress workout. The elapsed time is rendered as a
/// live timer from `startedAt`, so the system updates it without push.
struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            HStack(spacing: 14) {
                Image(systemName: context.state.symbol)
                    .font(.title)
                    .foregroundStyle(Theme.workoutsTint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.type).font(.headline)
                    Text("Workout in progress").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(context.state.startedAt, style: .timer)
                    .font(.title2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Theme.workoutsTint)
                    .frame(maxWidth: 90, alignment: .trailing)
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.35))
            .activitySystemActionForegroundColor(Theme.workoutsTint)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.type, systemImage: context.state.symbol)
                        .foregroundStyle(Theme.workoutsTint)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.startedAt, style: .timer)
                        .monospacedDigit()
                        .frame(maxWidth: 80, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Keep it up — tap to finish in Halo.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: context.state.symbol).foregroundStyle(Theme.workoutsTint)
            } compactTrailing: {
                Text(context.state.startedAt, style: .timer)
                    .monospacedDigit()
                    .frame(maxWidth: 44)
            } minimal: {
                Image(systemName: context.state.symbol).foregroundStyle(Theme.workoutsTint)
            }
            .keylineTint(Theme.workoutsTint)
        }
    }
}

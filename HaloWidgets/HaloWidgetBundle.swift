import WidgetKit
import SwiftUI

@main
struct HaloWidgetBundle: WidgetBundle {
    var body: some Widget {
        CalorieRingWidget()
        UpcomingTodosWidget()
        HabitStreakWidget()
        WorkoutLiveActivity()
        LogWaterControl()
        CompleteHabitControl()
        MarkPillTakenControl()
        TalkToHaloControl()
    }
}

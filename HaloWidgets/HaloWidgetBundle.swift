import WidgetKit
import SwiftUI

@main
struct HaloWidgetBundle: WidgetBundle {
    var body: some Widget {
        CalorieRingWidget()
        UpcomingTodosWidget()
        WorkoutLiveActivity()
        LogWaterControl()
        TalkToHaloControl()
    }
}

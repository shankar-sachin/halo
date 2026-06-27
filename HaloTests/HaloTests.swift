import Testing
import Foundation
@testable import Halo

struct FoodDatabaseTests {
    @Test func matchesExactFood() {
        let db = FoodDatabase()
        #expect(db.match("greek yogurt")?.calories == 150)
    }

    @Test func matchesWithinPhrase() {
        let db = FoodDatabase()
        let food = db.match("I ate one cup of greek yogurt")
        #expect(food?.name == "greek yogurt")
    }

    @Test func prefersMoreSpecificMatch() {
        let db = FoodDatabase()
        // "brown rice" should win over the generic "rice".
        #expect(db.match("a bowl of brown rice")?.name == "brown rice")
    }

    @Test func returnsNilForUnknown() {
        let db = FoodDatabase()
        #expect(db.match("zxqv nonsense") == nil)
    }
}

struct DateTimeParserTests {
    private let cal = Calendar.current

    @Test func parsesTimeToday() {
        let parser = DateTimeParser()
        let ref = cal.date(from: DateComponents(year: 2026, month: 6, day: 24, hour: 9))!
        let date = parser.parseDate(from: "eat yogurt by 5:30 pm today", referenceDate: ref)
        let comps = cal.dateComponents([.hour, .minute], from: date ?? .distantPast)
        #expect(comps.hour == 17)
        #expect(comps.minute == 30)
    }

    @Test func stripsTimeFromTitle() {
        let parser = DateTimeParser()
        let title = parser.strippedTitle(from: "eat one cup of greek yogurt by 5:30 pm today")
        #expect(title == "eat one cup of greek yogurt")
    }

    @Test func returnsNilWhenNoTime() {
        let parser = DateTimeParser()
        #expect(parser.parseDate(from: "buy groceries") == nil)
    }
}

struct TodoMatcherTests {
    @Test func matchesPhraseToTodo() {
        let matcher = TodoMatcher()
        let titles = ["call the dentist", "eat one cup of greek yogurt", "submit taxes"]
        let index = matcher.bestMatchIndex(for: "I finished eating greek yogurt", in: titles)
        #expect(index == 1)
    }

    @Test func returnsNilWhenNoGoodMatch() {
        let matcher = TodoMatcher()
        let titles = ["call the dentist", "submit taxes"]
        #expect(matcher.bestMatchIndex(for: "walk the dog", in: titles) == nil)
    }
}

@MainActor
struct VoiceCommandRouterTests {
    @Test func classifiesTodoWithWakeWord() {
        let (action, payload) = VoiceCommandRouter().classify("Halo, add a to-do to call mom at 6pm")
        #expect(action == .todo)
        #expect(payload == "call mom at 6pm")
    }

    @Test func classifiesNote() {
        let (action, payload) = VoiceCommandRouter().classify("Halo add a note that I shipped the release")
        #expect(action == .note)
        #expect(payload == "I shipped the release")
    }

    @Test func classifiesMeal() {
        let (action, payload) = VoiceCommandRouter().classify("Halo, log that I ate a cup of greek yogurt")
        #expect(action == .meal)
        #expect(payload == "a cup of greek yogurt")
    }

    @Test func classifiesCompletion() {
        let (action, payload) = VoiceCommandRouter().classify("Halo I finished eating greek yogurt at 5:15 pm")
        #expect(action == .complete)
        #expect(payload.contains("greek yogurt"))
    }

    @Test func defaultsToTodoWhenNoKeyword() {
        let (action, _) = VoiceCommandRouter().classify("Halo buy groceries tomorrow")
        #expect(action == .todo)
    }

    @Test func classifiesWater() {
        #expect(VoiceCommandRouter().classify("Halo log a glass of water").action == .water)
    }

    @Test func classifiesWorkout() {
        #expect(VoiceCommandRouter().classify("Halo log a 30 minute run").action == .workout)
    }

    @Test func classifiesMood() {
        #expect(VoiceCommandRouter().classify("Halo I feel great today").action == .mood)
    }

    @Test func classifiesAddVsCompleteHabit() {
        #expect(VoiceCommandRouter().classify("Halo add a habit to meditate").action == .addHabit)
        #expect(VoiceCommandRouter().classify("Halo mark my meditation habit done").action == .habit)
    }

    @Test func classifiesPill() {
        #expect(VoiceCommandRouter().classify("Halo I ate my digestion pill").action == .pill)
        #expect(VoiceCommandRouter().classify("Halo I took my vitamin D").action == .pill)
    }

    @Test func stripsLeadingThatFromSiriCommand() {
        // "tell Halo that I ate my digestion pill" arrives as "that I ate my digestion pill".
        let (action, _) = VoiceCommandRouter().classify("that I ate my digestion pill")
        #expect(action == .pill)
    }

    @Test func classifiesQuery() {
        #expect(VoiceCommandRouter().classify("Halo how many calories do I have left").action == .query)
        #expect(VoiceCommandRouter().classify("Halo what's on my to-do list").action == .query)
        #expect(VoiceCommandRouter().classify("Halo how much water today?").action == .query)
    }

    @Test func classifiesBriefing() {
        #expect(VoiceCommandRouter().classify("Halo how's my day").action == .briefing)
        #expect(VoiceCommandRouter().classify("Halo give me a summary").action == .briefing)
    }

    @Test func classifiesDelete() {
        #expect(VoiceCommandRouter().classify("Halo delete the milk to-do").action == .delete)
        #expect(VoiceCommandRouter().classify("Halo remove my last water").action == .delete)
    }

    @Test func classifiesEdit() {
        #expect(VoiceCommandRouter().classify("Halo reschedule call mom to 7pm").action == .edit)
        #expect(VoiceCommandRouter().classify("Halo rename groceries to buy oat milk").action == .edit)
    }

    @Test func deleteIsNotMistakenForCreate() {
        // "delete the milk to-do" must not be read as a new .todo.
        #expect(VoiceCommandRouter().classify("Halo delete the milk to-do").action != .todo)
    }

    @Test func classifiesInsights() {
        #expect(VoiceCommandRouter().classify("Halo how was my week").action == .insights)
        #expect(VoiceCommandRouter().classify("Halo show me my weekly insights").action == .insights)
    }

    @Test func classifiesSuggest() {
        #expect(VoiceCommandRouter().classify("Halo what should I eat").action == .suggest)
        #expect(VoiceCommandRouter().classify("Halo suggest a meal").action == .suggest)
    }

    @Test func classifiesExtractTodos() {
        #expect(VoiceCommandRouter().classify("Halo pull to-dos from my last note").action == .extractTodos)
        #expect(VoiceCommandRouter().classify("Halo turn my note into to-dos").action == .extractTodos)
    }
}

struct WorkoutCaloriesTests {
    @Test func runEstimateIsSane() {
        let kcal = WorkoutCalories.estimate(type: "Run", minutes: 30)
        #expect(kcal > 250 && kcal < 450)
    }

    @Test func longerWorkoutBurnsMore() {
        #expect(WorkoutCalories.estimate(type: "Cycling", minutes: 60) > WorkoutCalories.estimate(type: "Cycling", minutes: 20))
    }

    @Test func zeroMinutesIsZero() {
        #expect(WorkoutCalories.estimate(type: "Run", minutes: 0) == 0)
    }
}

@MainActor
struct NoteTaskSplittingTests {
    @Test func splitsCommaList() {
        let tasks = CommandActions.splitTasks("buy milk, call plumber, book flights")
        #expect(tasks.count == 3)
    }

    @Test func splitsLinesAndAnd() {
        let tasks = CommandActions.splitTasks("wash the car\nmow the lawn and rake leaves")
        #expect(tasks.count == 3)
    }
}

struct VoiceParsingTests {
    @Test func parsesWaterAmounts() {
        #expect(VoiceParsing.waterML(from: "a glass of water") == 250)
        #expect(VoiceParsing.waterML(from: "a bottle of water") == 500)
        #expect(VoiceParsing.waterML(from: "500 ml of water") == 500)
        #expect(VoiceParsing.waterML(from: "two glasses") == 500)
    }

    @Test func parsesWorkout() {
        let w = VoiceParsing.workout(from: "a 30 minute run")
        #expect(w.minutes == 30)
        #expect(w.type == "Run")
    }

    @Test func extractsHabitName() {
        #expect(VoiceParsing.habitName(from: "add a habit to meditate") == "meditate")
    }

    @Test func parsesPillNameAndPurpose() {
        let a = VoiceParsing.pill(from: "I ate my digestion pill")
        #expect(a.name == "Digestion Pill")
        #expect(a.purpose.isEmpty)

        let b = VoiceParsing.pill(from: "I took vitamin D for immunity")
        #expect(b.name == "Vitamin D")
        #expect(b.purpose == "immunity")
    }

    @Test func parsesWeightInKilograms() {
        #expect(VoiceParsing.weightKg(from: "log my weight 80 kilos") == 80)
        #expect(VoiceParsing.weightKg(from: "82.5 kg") == 82.5)
    }

    @Test func parsesWeightInPoundsAsKilograms() {
        let kg = VoiceParsing.weightKg(from: "I weigh 176 pounds")
        #expect(kg != nil)
        #expect(abs((kg ?? 0) - 79.8) < 0.5)
    }

    @Test func weightReturnsNilWithoutNumber() {
        #expect(VoiceParsing.weightKg(from: "log my weight") == nil)
    }

    @Test func parsesSleepHours() {
        #expect(VoiceParsing.sleepHours(from: "I slept 7 hours") == 7)
        #expect(VoiceParsing.sleepHours(from: "8.5 hours of sleep") == 8.5)
    }

    @Test func sleepReturnsNilWithoutNumber() {
        #expect(VoiceParsing.sleepHours(from: "I slept well") == nil)
    }
}

@MainActor
struct NewVoiceRoutingTests {
    @Test func classifiesWeight() {
        #expect(VoiceCommandRouter().classify("Halo log my weight 80 kilos").action == .weight)
        #expect(VoiceCommandRouter().classify("Halo I weigh 176 pounds").action == .weight)
    }

    @Test func classifiesSleep() {
        #expect(VoiceCommandRouter().classify("Halo I slept 7 hours").action == .sleep)
    }

    @Test func classifiesMedicationSchedule() {
        let (action, _) = VoiceCommandRouter().classify("Halo remind me to take vitamin D at 9am every day")
        #expect(action == .pillSchedule)
    }

    @Test func plainPillIsNotASchedule() {
        #expect(VoiceCommandRouter().classify("Halo I took my vitamin D").action == .pill)
    }

    @Test func classifiesReflect() {
        #expect(VoiceCommandRouter().classify("Halo wrap up my day").action == .reflect)
    }
}

struct PastIntervalTests {
    private let cal = Calendar.current

    @Test func resolvesYesterday() {
        let parser = DateTimeParser()
        let ref = cal.date(from: DateComponents(year: 2026, month: 6, day: 24, hour: 9))!
        let interval = parser.pastInterval(from: "what did I eat yesterday", referenceDate: ref)
        #expect(interval?.label == "yesterday")
        let start = interval?.start
        #expect(start == cal.date(from: DateComponents(year: 2026, month: 6, day: 23)))
    }

    @Test func resolvesDaysAgo() {
        let parser = DateTimeParser()
        let ref = cal.date(from: DateComponents(year: 2026, month: 6, day: 24, hour: 9))!
        let interval = parser.pastInterval(from: "how much water 3 days ago", referenceDate: ref)
        #expect(interval?.start == cal.date(from: DateComponents(year: 2026, month: 6, day: 21)))
    }

    @Test func resolvesWeekday() {
        let parser = DateTimeParser()
        // 2026-06-24 is a Wednesday; "Monday" should resolve to 2026-06-22.
        let ref = cal.date(from: DateComponents(year: 2026, month: 6, day: 24, hour: 9))!
        let interval = parser.pastInterval(from: "what did I eat on Monday", referenceDate: ref)
        #expect(interval?.start == cal.date(from: DateComponents(year: 2026, month: 6, day: 22)))
    }

    @Test func returnsNilWithoutPastReference() {
        let parser = DateTimeParser()
        #expect(parser.pastInterval(from: "how much water today") == nil)
    }
}

struct CorrelationEngineTests {
    private let cal = Calendar.current

    private func day(_ offset: Int, from ref: Date) -> Date {
        cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: ref))!
    }

    @Test func findsMoodWorkoutPattern() {
        let ref = cal.date(from: DateComponents(year: 2026, month: 6, day: 24, hour: 9))!
        var moods: [MoodEntry] = []
        var workouts: [Workout] = []
        // Workout days (offsets -1,-3,-5,-7) get high mood; rest days get low mood.
        for offset in [-1, -3, -5, -7] {
            moods.append(MoodEntry(rating: 5, loggedAt: day(offset, from: ref)))
            workouts.append(Workout(type: "Run", durationMinutes: 30, calories: 300, loggedAt: day(offset, from: ref)))
        }
        for offset in [-2, -4, -6, -8] {
            moods.append(MoodEntry(rating: 2, loggedAt: day(offset, from: ref)))
        }
        let result = CorrelationEngine.correlations(
            moods: moods, workouts: workouts, water: [], habits: [], sleeps: [],
            waterGoal: 2000, sleepGoal: 8, days: 21, now: ref
        )
        #expect(result.contains { $0.symbol == "figure.run" })
        #expect((result.first?.delta ?? 0) > 2.5)
    }

    @Test func respectsMinimumSampleGuard() {
        let ref = cal.date(from: DateComponents(year: 2026, month: 6, day: 24, hour: 9))!
        // Only two workout days — below the minSamples threshold, so no pattern.
        let moods = [MoodEntry(rating: 5, loggedAt: day(-1, from: ref)),
                     MoodEntry(rating: 5, loggedAt: day(-2, from: ref)),
                     MoodEntry(rating: 2, loggedAt: day(-3, from: ref)),
                     MoodEntry(rating: 2, loggedAt: day(-4, from: ref))]
        let workouts = [Workout(type: "Run", durationMinutes: 30, calories: 300, loggedAt: day(-1, from: ref)),
                        Workout(type: "Run", durationMinutes: 30, calories: 300, loggedAt: day(-2, from: ref))]
        let result = CorrelationEngine.correlations(
            moods: moods, workouts: workouts, water: [], habits: [], sleeps: [],
            waterGoal: 2000, sleepGoal: 8, days: 21, now: ref
        )
        #expect(result.isEmpty)
    }
}

struct RecurrenceTests {
    private let cal = Calendar.current

    @Test func dailyAdvancesOneDay() {
        let base = cal.date(from: DateComponents(year: 2026, month: 6, day: 24, hour: 17, minute: 30))!
        let next = Recurrence.daily.nextDate(after: base, calendar: cal)
        #expect(next == cal.date(byAdding: .day, value: 1, to: base))
    }

    @Test func weeklyAdvancesSevenDays() {
        let base = cal.date(from: DateComponents(year: 2026, month: 6, day: 24, hour: 9))!
        let next = Recurrence.weekly.nextDate(after: base, calendar: cal)
        #expect(next == cal.date(byAdding: .day, value: 7, to: base))
    }

    @Test func noneHasNoNextDate() {
        #expect(Recurrence.none.nextDate(after: .now) == nil)
    }
}

struct MealSuggesterTests {
    @Test func vegetarianNeverGetsMeatOrFish() {
        let s = MealSuggester.suggestion(dietType: .vegetarian, allergies: "", remaining: 1500).lowercased()
        #expect(!s.contains("chicken"))
        #expect(!s.contains("salmon"))
        #expect(!s.contains("tuna"))
    }

    @Test func veganExcludesDairyAndEggs() {
        let s = MealSuggester.suggestion(dietType: .vegan, allergies: "", remaining: 1500).lowercased()
        #expect(!s.contains("yogurt"))
        #expect(!s.contains("paneer"))
        #expect(!s.contains("egg"))
    }

    @Test func allergenIsFilteredOut() {
        // Dairy allergy should drop yogurt/paneer even for an omnivore.
        let s = MealSuggester.suggestion(dietType: .omnivore, allergies: "Dairy", remaining: 1500).lowercased()
        #expect(!s.contains("yogurt"))
        #expect(!s.contains("paneer"))
    }

    @Test func respectsRemainingBudget() {
        // With little budget, only light options should appear (all picks <= remaining).
        let s = MealSuggester.suggestion(dietType: .omnivore, allergies: "", remaining: 200)
        #expect(!s.contains("550"))
        #expect(!s.contains("600"))
    }

    @Test func omnivoreCanGetFishOrMeat() {
        let s = MealSuggester.suggestion(dietType: .omnivore, allergies: "", remaining: 1500).lowercased()
        #expect(s.contains("salmon") || s.contains("tuna") || s.contains("chicken"))
    }
}

struct TreatSuggesterTests {
    @Test func suggestsTreatWhenRoomRemains() {
        let (_, body) = TreatSuggester().message(consumed: 1250, budget: 2000)
        #expect(body.contains("750 kcal left"))
    }

    @Test func warnsWhenOverBudget() {
        let (title, _) = TreatSuggester().message(consumed: 2200, budget: 2000)
        #expect(title == "Daily budget reached")
    }
}

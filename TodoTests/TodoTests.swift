import Testing
import Foundation
@testable import Todo

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

import Foundation
import SwiftData

@Model
final class PillLog {
    /// Which pill, e.g. "Digestion Pill" or "Vitamin D".
    var name: String
    /// What it's used for, e.g. "digestion" (optional).
    var purpose: String
    var loggedAt: Date

    init(name: String, purpose: String = "", loggedAt: Date = .now) {
        self.name = name
        self.purpose = purpose
        self.loggedAt = loggedAt
    }
}

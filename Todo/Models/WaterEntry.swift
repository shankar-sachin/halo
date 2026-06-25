import Foundation
import SwiftData

@Model
final class WaterEntry {
    /// Amount in millilitres.
    var amountML: Int
    var loggedAt: Date

    init(amountML: Int, loggedAt: Date = .now) {
        self.amountML = amountML
        self.loggedAt = loggedAt
    }

    /// One glass of water.
    static let glassML = 250
}

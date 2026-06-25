import Foundation
import SwiftData

@Model
final class Note {
    /// Plain-text version, kept in sync for search and titles.
    var body: String
    /// JSON-encoded `AttributedString` for rich formatting (nil for plain/voice notes).
    var contentData: Data?
    var createdAt: Date

    init(body: String, contentData: Data? = nil, createdAt: Date = .now) {
        self.body = body
        self.contentData = contentData
        self.createdAt = createdAt
    }

    /// The rich content, falling back to plain text.
    var attributed: AttributedString {
        get {
            if let contentData, let decoded = try? JSONDecoder().decode(AttributedString.self, from: contentData) {
                return decoded
            }
            return AttributedString(body)
        }
        set {
            body = String(newValue.characters)
            contentData = try? JSONEncoder().encode(newValue)
        }
    }

    /// A short title derived from the first line of the note.
    var title: String {
        let firstLine = body
            .split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: true)
            .first
            .map(String.init) ?? ""
        let trimmed = firstLine.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "New Note" : trimmed
    }
}

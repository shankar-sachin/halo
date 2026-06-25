import Foundation

/// Fuzzy-matches a spoken phrase ("I finished eating one cup of greek yogurt") against the
/// titles of open to-dos, so the right task can be completed by voice.
struct TodoMatcher {
    /// Filler words that shouldn't influence matching.
    private static let stopWords: Set<String> = [
        "i", "the", "a", "an", "of", "one", "my", "to", "do", "did",
        "finished", "completed", "done", "eating", "ate", "eat", "had", "have",
        "task", "todo", "to-do", "cup", "cups", "with",
    ]

    /// Returns the index of the best-matching candidate title, or `nil` if none clears the bar.
    func bestMatchIndex(for phrase: String, in titles: [String]) -> Int? {
        let target = tokens(from: phrase)
        guard !target.isEmpty else { return nil }

        var best: (index: Int, score: Double)?
        for (index, title) in titles.enumerated() {
            let candidate = tokens(from: title)
            guard !candidate.isEmpty else { continue }
            let overlap = target.intersection(candidate)
            guard !overlap.isEmpty else { continue }
            // Jaccard-style score favouring strong overlap with the candidate.
            let score = Double(overlap.count) / Double(min(target.count, candidate.count))
            if best == nil || score > best!.score {
                best = (index, score)
            }
        }
        guard let best, best.score >= 0.5 else { return nil }
        return best.index
    }

    private func tokens(from text: String) -> Set<String> {
        let normalized = FoodDatabase.normalize(text)
        let words = normalized.split(separator: " ").map(String.init)
        return Set(words.filter { !$0.isEmpty && !TodoMatcher.stopWords.contains($0) })
    }
}

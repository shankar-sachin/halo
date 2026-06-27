import SwiftUI

/// Diet-type selector chips, shared by onboarding and Settings.
struct DietTypeChips: View {
    @Binding var rawValue: String

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(DietType.allCases) { type in
                let selected = rawValue == type.rawValue
                Button {
                    rawValue = type.rawValue
                } label: {
                    Label(type.label, systemImage: type.icon)
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .glassEffect(
                            selected ? Glass.regular.tint(Theme.dietTint.opacity(0.35)).interactive()
                                     : Glass.regular.interactive(),
                            in: .capsule
                        )
                        .overlay(
                            Capsule().stroke(Theme.dietTint.opacity(selected ? 0.9 : 0), lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
                .foregroundStyle(selected ? Theme.dietTint : .primary)
            }
        }
    }
}

/// Tappable chips for common allergens plus a free-text field for anything else.
struct AllergenChips: View {
    @Binding var allergies: String

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(DietPreferences.commonAllergens, id: \.self) { allergen in
                    let on = DietPreferences.contains(allergies, allergen)
                    Button {
                        allergies = DietPreferences.toggling(allergies, allergen)
                    } label: {
                        Text(allergen)
                            .font(.caption.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .glassEffect(
                                on ? Glass.regular.tint(Theme.pillsTint.opacity(0.35)).interactive()
                                   : Glass.regular.interactive(),
                                in: .capsule
                            )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(on ? Theme.pillsTint : .primary)
                }
            }
            TextField("Other allergies (comma separated)", text: $allergies, axis: .vertical)
                .lineLimit(1...3)
                .textFieldStyle(.roundedBorder)
                .font(.subheadline)
        }
    }
}

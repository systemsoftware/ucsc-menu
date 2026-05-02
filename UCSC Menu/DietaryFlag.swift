import SwiftUI

// MARK: - DietaryFlag
enum DietaryFlag: String, CaseIterable, Identifiable {
    // Lifestyle
    case vegan, vegetarian, halal
    // Allergens
    case gluten, wheat, eggs, milk, fish, shellfish, soy, nuts, treeNuts, sesame
    // Informational
    case beef, pork, alcohol

    var id: String { rawValue }

    var label: String {
        switch self {
        case .vegan:       return "Vegan"
        case .vegetarian:  return "Vegetarian"
        case .halal:       return "Halal"
        case .gluten:      return "Gluten"
        case .wheat:       return "Wheat"
        case .eggs:        return "Eggs"
        case .milk:        return "Milk"
        case .fish:        return "Fish"
        case .shellfish:   return "Shellfish"
        case .soy:         return "Soy"
        case .nuts:        return "Peanuts"
        case .treeNuts:    return "Tree Nuts"
        case .sesame:      return "Sesame"
        case .beef:        return "Beef"
        case .pork:        return "Pork"
        case .alcohol:     return "Alcohol"
        }
    }

    var symbol: String {
        switch self {
        case .vegan:       return "leaf.fill"
        case .vegetarian:  return "carrot.fill"
        case .halal:       return "moon.stars.fill"
        case .gluten:      return "allergens"
        case .wheat:       return "wind"
        case .eggs:        return "oval.fill"
        case .milk:        return "cup.and.heat.waves.fill"
        case .fish:        return "fish.fill"
        case .shellfish:   return "fossil.shell.fill"
        case .soy:         return "leaf.circle.fill"
        case .nuts:        return "sparkle"
        case .treeNuts:    return "tree.fill"
        case .sesame:      return "circle.grid.3x3.fill"
        case .beef:        return "b.circle.fill"
        case .pork:        return "p.circle.fill"
        case .alcohol:     return "wineglass.fill"
        }
    }

    var color: Color {
        switch self {
        case .vegan:       return .green
        case .vegetarian:  return Color(red: 0.55, green: 0.8, blue: 0.2)
        case .halal:       return .teal
        case .gluten:      return .orange
        case .wheat:       return Color(red: 0.9, green: 0.7, blue: 0.3)
        case .eggs:        return .yellow
        case .milk:        return Color(red: 0.85, green: 0.92, blue: 1.0)
        case .fish:        return .blue
        case .shellfish:   return Color(red: 0.6, green: 0.8, blue: 0.9)
        case .soy:         return Color(red: 0.45, green: 0.6, blue: 0.3)
        case .nuts:        return Color(red: 0.8, green: 0.6, blue: 0.3)
        case .treeNuts:    return Color(red: 0.55, green: 0.38, blue: 0.2)
        case .sesame:      return Color(red: 0.85, green: 0.72, blue: 0.45)
        case .beef:        return Color(red: 0.7, green: 0.2, blue: 0.15)
        case .pork:        return Color(red: 0.9, green: 0.4, blue: 0.5)
        case .alcohol:     return Color(red: 0.55, green: 0.15, blue: 0.55)
        }
    }

    var section: Section {
        switch self {
        case .vegan, .vegetarian, .halal:                        return .lifestyle
        case .gluten, .wheat, .eggs, .milk, .fish, .shellfish,
             .soy, .nuts, .treeNuts, .sesame:                    return .allergens
        case .beef, .pork, .alcohol:                             return .informational
        }
    }

    enum Section: String, CaseIterable {
        case lifestyle     = "Lifestyle"
        case allergens     = "Allergens"
        case informational = "Contains"
    }

    func matches(_ item: MenuItem) -> Bool {
        switch self {
        case .vegan:       return item.isVegan
        case .vegetarian:  return item.isVegetarian
        case .halal:       return item.isHalal
        case .gluten:      return item.containsGluten
        case .wheat:       return item.containsWheat
        case .eggs:        return item.containsEggs
        case .milk:        return item.containsMilk
        case .fish:        return item.containsFish
        case .shellfish:   return item.containsShellfish
        case .soy:         return item.containsSoy
        case .nuts:        return item.containsNuts
        case .treeNuts:    return item.containsTreeNuts
        case .sesame:      return item.containsSesame
        case .beef:        return item.containsBeef
        case .pork:        return item.containsPork
        case .alcohol:     return item.containsAlcohol
        }
    }
}

// MARK: - Filtering helpers

extension MenuCategory {
    func filtered(by active: Set<DietaryFlag>) -> MenuCategory? {
        guard !active.isEmpty else { return self }
        let kept = items.filter { item in active.contains { $0.matches(item) } }
        guard !kept.isEmpty else { return nil }
        return MenuCategory(categoryName: categoryName, items: kept)
    }
}

extension Meal {
    func filtered(by active: Set<DietaryFlag>) -> Meal? {
        guard !active.isEmpty else { return self }
        let kept = categories.compactMap { $0.filtered(by: active) }
        guard !kept.isEmpty else { return nil }
        return Meal(mealName: mealName, categories: kept)
    }
}

// MARK: - FlagFilterSheet
struct FlagFilterSheet: View {
    @Binding var activeFlags: Set<DietaryFlag>
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("infoType") var infoType = 0

    var body: some View {
        NavigationStack {
            List {

                Section("Settings") {
                    Picker("Dietary Tags", selection:$infoType) {
                        Text("Full").tag(0)
                        Text("Compact").tag(1)
                        Text("Hidden").tag(2)
                    }
                }

                ForEach(DietaryFlag.Section.allCases, id: \.self) { section in
                    let flags = DietaryFlag.allCases.filter { $0.section == section }
                    Section(section.rawValue) {
                        ForEach(flags) { flag in
                            FlagToggleRow(flag: flag, activeFlags: $activeFlags)
                        }
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") { activeFlags.removeAll() }
                        .disabled(activeFlags.isEmpty)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct FlagToggleRow: View {
    let flag: DietaryFlag
    @Binding var activeFlags: Set<DietaryFlag>

    private var isOn: Bool { activeFlags.contains(flag) }

    var body: some View {
        Button {
            if isOn { activeFlags.remove(flag) } else { activeFlags.insert(flag) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: flag.symbol)
                    .foregroundStyle(flag.color)
                    .frame(width: 24)
                Text(flag.label)
                    .foregroundStyle(.primary)
                Spacer()
                if isOn {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Toolbar button (use this inside your view's .toolbar modifier)

struct FlagFilterButton: View {
    @Binding var activeFlags: Set<DietaryFlag>
    @State private var showSheet = false

    var body: some View {
        Button { showSheet = true } label: {
            Image(systemName: activeFlags.isEmpty
                  ? "line.3.horizontal.decrease.circle"
                  : "line.3.horizontal.decrease.circle.fill")
        }
        .sheet(isPresented: $showSheet) {
            FlagFilterSheet(activeFlags: $activeFlags)
        }
    }
}

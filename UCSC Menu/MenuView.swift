import SwiftUI

import SwiftUI

import SwiftUI

struct MenuView: View {
    var provider: UCSCDiningProvider
    var location: DiningLocation
    
    @State var menu: [Meal] = []
    @State private var isLoading = true

    @State private var selectedMealName: String = ""

    var availableMeals: [String] {
        menu.map { $0.mealName }
    }

    var filteredMenu: [Meal] {
        selectedMealName != "all" ? menu.filter { $0.mealName == selectedMealName } : menu
    }

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Fetching Menu...")
                    .glassBackground()
            } else {
                VStack(spacing: 0) {

                    if availableMeals.count > 1 {
                        Picker("Meal", selection: $selectedMealName) {
                            Text("All").tag("all")
                            ForEach(availableMeals, id: \.self) { name in
                                Text(name).tag(name)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding()
                        .background(.ultraThinMaterial)
                    }

                    ScrollView {
                        VStack(spacing: 25) {
                            ForEach(filteredMenu) { meal in
                                MealSection(meal: meal)
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        Task {
                            if let url = provider.getMenuURL(for: location)?.absoluteString {
                                let fetched = await fetchAndParseMenu(urlString: url)
                                self.menu = fetched
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(location.name.removingPercentEncoding?.replacingOccurrences(of: "+", with: " ") ?? location.name)
        .onAppear {
            Task {
                if let url = provider.getMenuURL(for: location)?.absoluteString {
                    let fetched = await fetchAndParseMenu(urlString: url)
                    self.menu = fetched
                    
                    let nowHour = Calendar.current.component(.hour, from: Date())
                    
                    if availableMeals.count < 3 {
                        self.selectedMealName = "all"
                    } else if nowHour >= 8 && nowHour < 11 {
                            self.selectedMealName = "Breakfast"
                        } else if nowHour >= 11 && nowHour < 17 {
                            self.selectedMealName = "Lunch"
                        } else if nowHour >= 17 && nowHour < 20 {
                            self.selectedMealName = "Dinner"
                        } else if nowHour >= 20 || nowHour < 8 {
                            self.selectedMealName = "Late Night"
                        }
    
                    self.isLoading = false
                }
            }
        }
    }
}


struct MealSection: View {
    let meal: Meal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(meal.mealName.uppercased())
                .font(.system(.title3, design: .rounded, weight: .bold))
                .padding(.leading, 8)
                .foregroundColor(.secondary)

            VStack(spacing: 1) {
                ForEach(meal.categories) { category in
                    CategoryGroup(category: category)
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

struct CategoryGroup: View {
    let category: MenuCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if category.categoryName.count(where: { $0 == " " }) <= 5 {
                Text(category.categoryName)
                    .font(.caption.bold())
                    .foregroundColor(.accentColor)
                    .padding(.top, 10)
            }

            ForEach(category.items) { item in
                HStack {
                    Text(item.name)
                        .font(.body)
                    Spacer()
                    if item.isVegan {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                if item.id != category.items.last?.id {
                    Divider().opacity(0.2)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
}

extension View {
    func glassBackground() -> some View {
        self.padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(color: .black.opacity(0.1), radius: 10)
    }
}

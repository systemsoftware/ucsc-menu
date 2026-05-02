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
    
    @State private var activeFlags: Set<DietaryFlag> = []

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
                        VStack(alignment: .leading, spacing: 25) {
                            ForEach(filteredMenu) { meal in
                                MealSection(meal: meal, activeFlags:activeFlags, location:location)
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FlagFilterButton(activeFlags: $activeFlags)
            }
        }
    }
}


struct MealSection: View {
    let meal: Meal
    
    let activeFlags: Set<DietaryFlag>
    
    let location: DiningLocation
   
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(meal.mealName.uppercased())
                .font(.system(.title3, design: .rounded, weight: .bold))
                .padding(.leading, 8)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 1) {
                ForEach(meal.categories) { category in
                    CategoryGroup(category: category, activeFlags:activeFlags, location:location, mname: meal.mealName)
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
    @AppStorage("infoType") var showInfo = 0
    let activeFlags: Set<DietaryFlag>
    var location: DiningLocation
    var mname = ""
    
    var displayedItems: [MenuItem] {
        category.filtered(by: activeFlags)?.items ?? []
    }
    
    let today = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            if category.categoryName.split(separator: " ").count <= 5 {
                Text(category.categoryName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
                    .padding(.horizontal)
                    .padding(.top, 10)
            }
            

            ForEach(displayedItems) { item in
                NavigationLink {
                    NutritionLabelView(
                        item: item,
                        location: location,
                        date: today.formatted(.dateTime.month(.twoDigits).day(.twoDigits).year()),
                        mealName:mname
                    )
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.name)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                        
                        if showInfo != 2 {
                            FlagView(item: item, style: showInfo == 0 ? .detailed : .compact)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

            }
        }
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

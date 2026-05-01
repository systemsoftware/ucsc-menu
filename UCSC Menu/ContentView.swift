import SwiftUI

struct ContentView: View {
    let provider = UCSCDiningProvider()
    @State var locations: [DiningLocation] = []
    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    ForEach(locations) { location in
                        NavigationLink {
                            MenuView(provider: provider, location: location)
                        } label: {
                            LocationGlassCard(location: location)
                        }
                        .navigationLinkIndicatorVisibility(.hidden)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .onMove(perform: moveLocation)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("UCSC Dining")
            .toolbar {
                EditButton()
            }
            .environment(\.editMode, $editMode)
            .onAppear {
                Task {
                    let fetched = await provider.fetchAvailableLocations()
                    loadOrder(fetchedLocations: fetched)
                }
            }
        }
    }

    func moveLocation(from source: IndexSet, to destination: Int) {
        locations.move(fromOffsets: source, toOffset: destination)
        saveOrder()
    }
    
    func saveOrder() {
        if let encoded = try? JSONEncoder().encode(locations) {
            UserDefaults.standard.set(encoded, forKey: "SavedLocationOrder")
        }
    }

    func loadOrder(fetchedLocations: [DiningLocation]) {
        if let data = UserDefaults.standard.data(forKey: "SavedLocationOrder"),
           let savedOrder = try? JSONDecoder().decode([DiningLocation].self, from: data) {

            let currentIds = Set(fetchedLocations.map { $0.id })
            self.locations = savedOrder.filter { currentIds.contains($0.id) }
            
            let savedIds = Set(savedOrder.map { $0.id })
            let newLocations = fetchedLocations.filter { !savedIds.contains($0.id) }
            self.locations.append(contentsOf: newLocations)
        } else {
            self.locations = fetchedLocations
        }
    }
}

struct LocationGlassCard: View {
    let location: DiningLocation
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(location.name.split(separator: "+").joined(separator: " "))
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    ContentView()
}

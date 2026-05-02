import SwiftUI
import WebKit

struct NutritionLabelView: View {
    let item: MenuItem
    let location: DiningLocation
    let date: String
    let mealName: String

    @State private var labelURL: URL?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let url = labelURL {
                WebView(url: url)
            } else if isLoading {
                ProgressView("Loading nutrition info...")
            } else {
                ContentUnavailableView("Not available", systemImage: "fork.knife")
            }
        }
        .task {
            let lookup = await fetchRecNumLookup(for: location, mealName: mealName, date: date)
            
            print("lookup \(lookup) \(makeLabelURL(for: location, date: date, recNumAndPort: "0")!)")
            
            if let recNum = lookup[item.name] {
                labelURL = makeLabelURL(for: location, date: date, recNumAndPort: recNum)
                print("Found URL: \(labelURL!)")
            } else {
                print("Could not find \(item.name) in \(mealName)")
            }
            isLoading = false
        }
    }
}

import Foundation
import SwiftSoup

import Foundation
import SwiftSoup

// MARK: - Models
struct DiningLocation: Identifiable, Codable, Hashable {
    let id: String
    let name: String
}

// MARK: - Location Provider
class UCSCDiningProvider {
    static let rootURL = "https://nutrition.sa.ucsc.edu/"
    
    /// Scrapes the location.aspx page to get all current hall names and IDs
    func fetchAvailableLocations() async -> [DiningLocation] {
        guard let url = URL(string: UCSCDiningProvider.rootURL + "location.aspx") else { return [] }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let html = String(data: data, encoding: .utf8) ?? ""
            let doc = try SwiftSoup.parse(html)
            
            // Find all <a> tags inside the location list
            let links = try doc.select("li.locations a")
            
            return links.compactMap { link in
                guard let href = try? link.attr("href") else { return nil }
                
                // Extract locationNum and locationName from the URL query
                let components = URLComponents(string: href)
                let id = components?.queryItems?.first(where: { $0.name == "locationNum" })?.value
                let name = components?.queryItems?.first(where: { $0.name == "locationName" })?.value
                
                if let id = id, let name = name {
                    return DiningLocation(id: id, name: name)
                }
                return nil
            }
        } catch {
            print("Failed to discovery locations: \(error)")
            return []
        }
    }
    
    /// Generates a valid menu URL for a specific location
    func getMenuURL(for location: DiningLocation) -> URL? {
        var components = URLComponents(string: UCSCDiningProvider.rootURL + "shortmenu.aspx")
        components?.queryItems = [
            URLQueryItem(name: "sName", value: "UC Santa Cruz Dining"),
            URLQueryItem(name: "locationNum", value: location.id),
            URLQueryItem(name: "locationName", value: location.name),
            URLQueryItem(name: "naFlag", value: "1")
        ]
        return components?.url
    }
}

// MARK: - Models
struct MenuItem: Identifiable {
    let id = UUID()
    let name: String
    let containsGluten: Bool
    let isVegan: Bool
}

struct MenuCategory: Identifiable {
    let id = UUID()
    let categoryName: String
    var items: [MenuItem]
}

struct Meal: Identifiable {
    let id = UUID()
    let mealName: String
    var categories: [MenuCategory]
}


// MARK: - Parser Function
func fetchAndParseMenu(urlString: String) async -> [Meal] {
    guard let url = URL(string: urlString) else { return [] }
    
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        let doc: Document = try SwiftSoup.parse(html)
        
        let mealTables = try doc.select("td[width=50%]")
        var dailyMenus: [Meal] = []
        
        for mealTable in mealTables {
            let mealName = try mealTable.select(".shortmenumeals").text()
            if mealName.isEmpty { continue }
            
            var currentMeal = Meal(mealName: mealName, categories: [])
            let rows = try mealTable.select("tr")
            
            var currentCategory: MenuCategory? = nil
            
            for row in rows {
                if try !row.select(".shortmenuinstructs").isEmpty() ||
                   !row.select(".shortmenunutritive").isEmpty() {
                    continue
                }

                let categoryElement = try row.select(".shortmenucats")
                let recipeElement = try row.select(".shortmenurecipes")

                if !categoryElement.isEmpty() {
                    let catName = try categoryElement.text()
                        .replacingOccurrences(of: "--", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    
                    if catName.lowercased() == mealName.lowercased() || catName.count > 40 {
                        continue
                    }
                    
                    if let finishedCat = currentCategory, !finishedCat.items.isEmpty {
                        currentMeal.categories.append(finishedCat)
                    }
                    currentCategory = MenuCategory(categoryName: catName, items: [])
                    
                } else if !recipeElement.isEmpty() {
                    guard let nameElement = try recipeElement.select("span, a").first() else { continue }
                    let itemName = try nameElement.text().trimmingCharacters(in: .whitespaces)
                    
                    if itemName.lowercased().contains("go to top") || itemName.count < 2 {
                        continue
                    }

                    if currentCategory?.items.contains(where: { $0.name == itemName }) == true {
                        continue
                    }

                    let icons = try row.select("img").compactMap { try? $0.attr("src") }
                    let isVegan = icons.contains { $0.contains("vegan.gif") }
                    let hasGluten = icons.contains { $0.contains("gluten.gif") || $0.contains("wheat.gif") }
                    
                    let item = MenuItem(name: itemName, containsGluten: hasGluten, isVegan: isVegan)
                    currentCategory?.items.append(item)
                }
            }
            
            // Add the final category of the meal
            if let lastCat = currentCategory, !lastCat.items.isEmpty {
                currentMeal.categories.append(lastCat)
            }
            
            dailyMenus.append(currentMeal)
        }
        return dailyMenus
        
    } catch {
        print("Parsing error: \(error)")
        return []
    }
}

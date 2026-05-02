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
struct MenuItem: Identifiable, Hashable {
    let id = UUID()
    let name: String

    // Lifestyle / certifications
    let isVegan: Bool
    let isVegetarian: Bool
    let isHalal: Bool

    // Allergens
    let containsGluten: Bool
    let containsWheat: Bool
    let containsEggs: Bool
    let containsMilk: Bool
    let containsFish: Bool
    let containsShellfish: Bool
    let containsSoy: Bool
    let containsNuts: Bool       // peanuts / generic nuts
    let containsTreeNuts: Bool
    let containsSesame: Bool

    // Contains (informational)
    let containsBeef: Bool
    let containsPork: Bool
    let containsAlcohol: Bool
    
    var labelURL: URL? = nil
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

                    let item = MenuItem(
                        name: itemName,
                        // Lifestyle / certifications
                        isVegan:        icons.contains { $0.contains("vegan.gif") },
                        isVegetarian:   icons.contains { $0.contains("veggie.gif") },
                        isHalal:        icons.contains { $0.contains("halal.gif") },
                        // Allergens
                        containsGluten:    icons.contains { $0.contains("gluten.gif") },
                        containsWheat:     icons.contains { $0.contains("wheat.gif") },
                        containsEggs:      icons.contains { $0.contains("eggs.gif") },
                        containsMilk:      icons.contains { $0.contains("milk.gif") },
                        containsFish:      icons.contains { $0.contains("fish.gif") },
                        containsShellfish: icons.contains { $0.contains("shellfish.gif") },
                        containsSoy:       icons.contains { $0.contains("soy.gif") },
                        containsNuts:      icons.contains { $0.contains("nuts.gif") },
                        containsTreeNuts:  icons.contains { $0.contains("treenut.gif") },
                        containsSesame:    icons.contains { $0.contains("sesame.gif") },
                        // Contains (informational)
                        containsBeef:    icons.contains { $0.contains("beef.gif") },
                        containsPork:    icons.contains { $0.contains("pork.gif") },
                        containsAlcohol: icons.contains { $0.contains("alcohol.gif") }
                    )
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


func fetchRecNumLookup(for location: DiningLocation, mealName: String, date: String) async -> [String: String] {
    var components = URLComponents(string: UCSCDiningProvider.rootURL + "longmenu.aspx")
    components?.queryItems = [
        URLQueryItem(name: "sName",        value: "UC Santa Cruz Dining"),
        URLQueryItem(name: "locationNum",  value: location.id),
        URLQueryItem(name: "locationName", value: location.name),
        URLQueryItem(name: "naFlag",       value: "1"),
        URLQueryItem(name: "WeeksMenus",   value: "UCSC - This Week's Menus"),
        URLQueryItem(name: "dtdate",       value: date),   // "05/01/2026"
        URLQueryItem(name: "mealName",     value: mealName),
    ]
    guard let url = components?.url else { return [:] }

    guard let (data, _) = try? await URLSession.shared.data(from: url),
          let html = String(data: data, encoding: .utf8),
          let doc = try? SwiftSoup.parse(html) else { return [:] }

    var lookup: [String: String] = [:]
    if let links = try? doc.select("div.longmenucoldispname a") {
        for link in links {
            guard let href = try? link.attr("href"),
                  let name = try? link.text(),
                  let recNum = URLComponents(string: href)?
                .queryItems?.first(where: { $0.name == "RecNumAndPort" })?.value
            else { continue }
            lookup[name.trimmingCharacters(in: .whitespaces)] = recNum
        }
    }
    return lookup
}

func makeLabelURL(for location: DiningLocation, date: String, recNumAndPort: String) -> URL? {
    var components = URLComponents(string: UCSCDiningProvider.rootURL + "label.aspx")
    components?.queryItems = [
        URLQueryItem(name: "locationNum",  value: location.id),
        URLQueryItem(name: "locationName", value: location.name),
        URLQueryItem(name: "dtdate",       value: date),
        URLQueryItem(name: "RecNumAndPort", value: recNumAndPort),
    ]
    return components?.url
}

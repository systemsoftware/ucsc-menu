
# UCSC Dining Menu

An iOS application designed to provide a seamless, modern experience for checking daily dining hall menus at UC Santa Cruz. Built with SwiftUI, it features a "Liquid Glass" aesthetic, dynamic menu scraping, and customizable location ordering.

## Features
* Real-time Scraping: Dynamically fetches the latest dining locations and menus from the official UCSC Dining FoodPro website.
* Liquid Glass UI: A modern design language utilizing ultraThinMaterial and rounded layouts that adapt perfectly to Light and Dark Mode.
* Toggle between major meal periods (Breakfast, Lunch, Dinner, Late Night). • Filter dishes by dietary preferences (Vegan, Gluten-Free).
* Reordering: Drag and drop dining halls to prioritize your favorites. 
* Robust Parsing: High-accuracy HTML parsing using SwiftSoup to filter out navigational junk and metadata from the source tables.

## Technical Stack
* Language: Swift
* Framework: SwiftUI
* Library: SwiftSoup (HTML Parser)

## Installation
1. Clone the repository.
2. Add the SwiftSoup package via Swift Package Manager: https://github.com/scinfu/SwiftSoup.git
3. Build and run on an iOS simulator or device.

## Usage
1. Browse Locations: View all available UCSC dining locations on the home screen.
2. Reorder: Tap "Edit" in the top navigation bar to drag halls into your preferred order.
3. View Menu: Tap a location to see the daily offerings.
4. Filter: Use the segmented picker at the top of the menu view to jump between Breakfast, Lunch, and Dinner.


### Disclaimer: This project is an independent tool and is not officially affiliated with UC Santa Cruz Dining Services.
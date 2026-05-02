import SwiftUI

// MARK: - Flag Model

private struct MenuFlag {
    let symbol: String
    let label: String
    let color: Color
}

// MARK: - FlagView

struct FlagView: View {
    let item: MenuItem

    enum Style {
        case compact
        case detailed
    }

    var style: Style = .compact

    private var flags: [MenuFlag] {
        var result: [MenuFlag] = []

        // ── Lifestyle / certifications ──────────────────────────────────
        if item.isVegan {
            result.append(.init(symbol: "leaf.fill",           label: "Vegan",       color: .green))
        }
        if item.isVegetarian {
            result.append(.init(symbol: "carrot.fill",         label: "Vegetarian",  color: Color(red: 0.55, green: 0.8, blue: 0.2)))
        }
        if item.isHalal {
            result.append(.init(symbol: "moon.stars.fill",     label: "Halal",       color: .teal))
        }

        // ── Allergens ───────────────────────────────────────────────────
        if item.containsGluten {
            result.append(.init(symbol: "allergens",           label: "Gluten",      color: .orange))
        }
        if item.containsWheat {
            result.append(.init(symbol: "wind",                label: "Wheat",       color: Color(red: 0.9, green: 0.7, blue: 0.3)))
        }
        if item.containsEggs {
            result.append(.init(symbol: "oval.fill",           label: "Eggs",        color: .yellow))
        }
        if item.containsMilk {
            result.append(.init(symbol: "cup.and.heat.waves.fill", label: "Milk",    color: Color(red: 0.85, green: 0.92, blue: 1.0)))
        }
        if item.containsFish {
            result.append(.init(symbol: "fish.fill",           label: "Fish",        color: .blue))
        }
        if item.containsShellfish {
            result.append(.init(symbol: "fossil.shell.fill",   label: "Shellfish",   color: Color(red: 0.6, green: 0.8, blue: 0.9)))
        }
        if item.containsSoy {
            result.append(.init(symbol: "leaf.circle.fill",    label: "Soy",         color: Color(red: 0.45, green: 0.6, blue: 0.3)))
        }
        if item.containsNuts {
            result.append(.init(symbol: "sparkle",             label: "Peanuts",     color: Color(red: 0.8, green: 0.6, blue: 0.3)))
        }
        if item.containsTreeNuts {
            result.append(.init(symbol: "tree.fill",           label: "Tree Nuts",   color: Color(red: 0.55, green: 0.38, blue: 0.2)))
        }
        if item.containsSesame {
            result.append(.init(symbol: "circle.grid.3x3.fill", label: "Sesame",    color: Color(red: 0.85, green: 0.72, blue: 0.45)))
        }

        // ── Informational ───────────────────────────────────────────────
        if item.containsBeef {
            result.append(.init(symbol: "b.circle.fill",       label: "Beef",        color: Color(red: 0.7, green: 0.2, blue: 0.15)))
        }
        if item.containsPork {
            result.append(.init(symbol: "p.circle.fill",       label: "Pork",        color: Color(red: 0.9, green: 0.4, blue: 0.5)))
        }
        if item.containsAlcohol {
            result.append(.init(symbol: "wineglass.fill",      label: "Alcohol",     color: Color(red: 0.55, green: 0.15, blue: 0.55)))
        }

        return result
    }

    var body: some View {
        if flags.isEmpty {
            EmptyView()
        } else {
            switch style {
            case .compact:  compactBody
            case .detailed: detailedBody
            }
        }
    }

    private var compactBody: some View {
        HStack(spacing: 4) {
            ForEach(flags, id: \.label) { flag in
                Image(systemName: flag.symbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(flag.color)
                    .accessibilityLabel(flag.label)
            }
        }
    }

    private var detailedBody: some View {
        FlowLayout(spacing: 6) {
            ForEach(flags, id: \.label) { flag in
                Label(flag.label, systemImage: flag.symbol)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(flag.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(flag.color.opacity(0.12), in: Capsule())
                    .overlay(Capsule().strokeBorder(flag.color.opacity(0.3), lineWidth: 0.5))
            }
        }
    }
}

// MARK: - Minimal flow layout
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
                totalHeight = y
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalHeight = y + rowHeight
        }
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

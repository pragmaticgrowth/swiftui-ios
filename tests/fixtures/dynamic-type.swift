// Fixture — DELIBERATE iOS Dynamic Type violations for audit-swiftui-dynamic-type.
// Each block trips exactly one grep tell in ../../skills/audit-swiftui-dynamic-type/lint/grep-tells.tsv.
// Expected firing rule_ids: tests/fixtures/dynamic-type.expect
import SwiftUI

struct ArticleRow: View {
    let article: Article

    var body: some View {
        VStack(alignment: .leading) {
            // ❌ dt-01 — fixed .font(.system(size:)) on body text → never scales with Larger Text
            Text(article.title)
                .font(.system(size: 17))

            // ❌ dt-05 — one-line label with NO .minimumScaleFactor → truncates at large sizes
            Text(article.author)
                .font(.headline)
                .lineLimit(1)
        }
        // ❌ dt-04 — .dynamicTypeSize(.large) caps below the accessibility range → locks out large-text users
        .dynamicTypeSize(.large)
    }
}

struct SectionHeader: View {
    let section: Section
    // ❌ dt-02 — Font.system(size:) constructor for a heading → frozen size, the value-init form
    private let titleFont = Font.system(size: 20, weight: .semibold)

    var body: some View {
        Text(section.title)
            .font(titleFont)
    }
}

struct IconLabel: View {
    let item: Item

    var body: some View {
        HStack {
            // ❌ dt-03 — hard-coded icon .frame beside scalable text, no @ScaledMetric → frozen geometry
            Image(systemName: item.symbol)
                .frame(width: 44, height: 44)
            Text(item.name)
                .font(.body)
        }
    }
}

// Minimal stand-ins so the fixture parses.
struct Article { let title: String = "T"; let author: String = "A" }
struct Section { let title: String = "S" }
struct Item { let symbol: String = "star"; let name: String = "N" }
</content>

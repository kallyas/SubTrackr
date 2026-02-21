import SwiftUI

/// A view that displays text with highlighted search matches
struct HighlightedText: View {
    let text: String
    let searchText: String
    let font: Font
    let foregroundColor: Color
    let highlightColor: Color

    init(
        _ text: String,
        searchText: String,
        font: Font = DesignSystem.Typography.callout,
        foregroundColor: Color = DesignSystem.Colors.label,
        highlightColor: Color = DesignSystem.Colors.accent
    ) {
        self.text = text
        self.searchText = searchText
        self.font = font
        self.foregroundColor = foregroundColor
        self.highlightColor = highlightColor
    }

    var body: some View {
        if searchText.isEmpty {
            Text(text)
                .font(font)
                .foregroundStyle(foregroundColor)
        } else {
            highlightedContent
        }
    }

    private var highlightedContent: some View {
        let attributedString = createHighlightedText()
        return Text(attributedString)
    }

    private func createHighlightedText() -> AttributedString {
        var attributedString = AttributedString(text)

        // Find all ranges of the search text (case-insensitive)
        let lowercasedText = text.lowercased()
        let lowercasedSearch = searchText.lowercased()

        var searchStartIndex = lowercasedText.startIndex
        while let range = lowercasedText.range(of: lowercasedSearch, range: searchStartIndex..<lowercasedText.endIndex) {
            // Convert String range to AttributedString range
            let distance = lowercasedText.distance(from: lowercasedText.startIndex, to: range.lowerBound)
            let length = lowercasedText.distance(from: range.lowerBound, to: range.upperBound)

            let attrStart = attributedString.index(attributedString.startIndex, offsetByCharacters: distance)
            let attrEnd = attributedString.index(attrStart, offsetByCharacters: length)
            let attrRange = attrStart..<attrEnd

            // Apply highlight styling
            attributedString[attrRange].foregroundColor = highlightColor
            attributedString[attrRange].font = font.weight(.bold)
            attributedString[attrRange].backgroundColor = highlightColor.opacity(0.15)

            // Move search start to after this match
            searchStartIndex = range.upperBound
        }

        // Apply default styling to non-highlighted parts
        attributedString.font = font
        attributedString.foregroundColor = foregroundColor

        return attributedString
    }
}

#Preview {
    VStack(spacing: 20) {
        HighlightedText("Netflix Premium", searchText: "net")
        HighlightedText("Spotify Family Plan", searchText: "fam")
        HighlightedText("Apple Music", searchText: "")
        HighlightedText("Amazon Prime", searchText: "zon pri")
    }
    .padding()
}

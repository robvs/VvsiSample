//  Copyright © 2024 Rob Vander Sloot
//

import SwiftUI

struct CategoryView: View {
    @ObservedObject var viewState: CategoryViewState

    private let jokes = ["Chuck Norris joke 1.", "Chuck Norris joke 2.", "Chuck Norris joke 3."]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Random \(viewState.categoryName) Jokes")
                .appTitle2()

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(jokes, id: \.self) { joke in
                       row(with: joke)
                    }
                }
            }

            refreshButton
                .padding(.vertical, 16)
        }
        .padding(.top, 8)
        .padding(.horizontal, 16)
        .navigationTitle(viewState.categoryName.capitalized)
        .navigationBarTitleDisplayMode(.inline)
    }
}


// MARK: - Subviews

private extension CategoryView {

    var refreshButton: some View {
        HStack {
            Spacer(minLength: 0)

            Button("Refresh") {
                print("refresh button pressed.")
            }
            .buttonStyle(AppButtonStyle.Primary())

            Spacer(minLength: 0)
        }
    }
    func row(with joke: String) -> some View {
        HStack(spacing: 0) {
            Text(joke)
                .appBodyTextSmall()
                .italic()
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Previews

#Preview("Light") {
    CategoryView(viewState: CategoryViewState(categoryName: "Category 1"))
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    CategoryView(viewState: CategoryViewState(categoryName: "Category 1"))
        .preferredColorScheme(.dark)
}

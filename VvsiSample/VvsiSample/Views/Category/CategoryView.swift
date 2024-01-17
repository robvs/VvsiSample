//  Copyright © 2024 Rob Vander Sloot
//

import SwiftUI

/// Displays a set of random jokes for a specific category.
struct CategoryView: View {
    @ObservedObject var viewState: CategoryViewState

    private let placeHolderText = "If Chuck Norris goes to Z'ha'dum, he would not die."

    var body: some View {
        VStack(alignment: .leading) {
            Text("Random \(viewState.categoryName) Jokes")
                .appTitle2()

            if let errorMessage = viewState.errorMessage {
                Text(errorMessage)
                    .appTextError()
                    .padding(.top)
            }

            if viewState.isLoading {
                loadingPlaceholder()
            }
            else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewState.categoryJokes, id: \.self) { joke in
                            row(with: joke)
                        }
                    }
                }
            }

            refreshButton
                .padding(.vertical)
        }
        .padding(.top, 8)
        .padding(.horizontal)
        .navigationTitle(viewState.categoryName.capitalized)
        .navigationBarTitleDisplayMode(.inline)
    }
}


// MARK: - Subviews

private extension CategoryView {

    func loadingPlaceholder() -> some View {
        ScrollView {
            VStack(spacing: 16) {
                row(with: placeHolderText)
                row(with: placeHolderText)
                row(with: placeHolderText)
            }
            .redacted(reason: .placeholder)
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

    var refreshButton: some View {
        HStack {
            Spacer(minLength: 0)

            Button("Refresh") {
                viewState.on(event: .refreshButtonPressed)
            }
            .buttonStyle(AppButtonStyle.Primary())

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Previews

#Preview("loading") {
    CategoryView(viewState: CategoryViewState(categoryName: "Category 1"))
        .preferredColorScheme(.light)
}

#Preview("ready") {
    let viewState = CategoryViewState(categoryName: "Category 1")
    return CategoryView(viewState: viewState)
        .task {
            await viewState.set(state: .ready(categoryJokes: ["Joke 1", "Joke 2"]))
        }
        .preferredColorScheme(.light)
}

#Preview("error") {
    let viewState = CategoryViewState(categoryName: "Category 1")
    return CategoryView(viewState: viewState)
        .task {
            await viewState.set(state: .error(message: "Error message..."))
        }
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    CategoryView(viewState: CategoryViewState(categoryName: "Category 1"))
        .preferredColorScheme(.dark)
}

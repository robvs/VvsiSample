//  Copyright © 2024 Rob Vander Sloot
//

import SwiftUI

/// Displays a set of random jokes for a specific category.
struct CategoryView: View {
    @ObservedObject var viewState: CategoryViewState

    /// Convenience property to give direct access to `viewState.state`.
    private var state: CategoryViewState.State { viewState.state }

    private let placeHolderText = "If Chuck Norris goes to Z'ha'dum, he would not die."

    var body: some View {
        VStack(alignment: .leading) {
            Text("Random \(state.categoryName) Jokes")
                .appTitle2()

            if let errorMessage = state.errorMessage {
                Text(errorMessage)
                    .appTextError()
                    .padding(.top)
            }

            if state.isLoading {
                loadingPlaceholder()
            }
            else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(state.jokes, id: \.self) { joke in
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
        .navigationTitle(state.categoryName.capitalized)
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
                viewState.send(action: .refreshButtonPressed)
            }
            .buttonStyle(AppButtonStyle.Primary())
            .disabled(viewState.state.refreshButtonDisabled)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Previews

#Preview("loading") {
    return CategoryView(viewState: CategoryViewState(categoryName: "Category 1"))
        .preferredColorScheme(.light)
}

#Preview("ready") {
    let viewAgent = CategoryViewState(categoryName: "Category 1")
    return CategoryView(viewState: viewAgent)
        .task {
            let result = GetRandomJokesResult.success(["Joke 1", "Joke 2"])
            viewAgent.reduce(with: .getRandomJokesResult(result))
        }
        .preferredColorScheme(.light)
}

#Preview("error") {
    let viewAgent = CategoryViewState(categoryName: "Category 1")
    return CategoryView(viewState: viewAgent)
        .task {
            let result = GetRandomJokesResult.failure(AppUrlSession.RequestError.serverResponse(code: 404))
            viewAgent.reduce(with: .getRandomJokesResult(result))
        }
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    return CategoryView(viewState: CategoryViewState(categoryName: "Category 1"))
        .preferredColorScheme(.dark)
}

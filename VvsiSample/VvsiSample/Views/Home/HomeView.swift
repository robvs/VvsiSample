//  Copyright © 2024 Rob Vander Sloot
//

import OSLog
import SwiftUI

/// Displays a random joke and a list of available categories.
struct HomeView: View {
    @EnvironmentObject var navigationState: NavigationState
    @ObservedObject var viewState: HomeViewState

    /// Convenience property to give direct access to `viewState.state`.
    private var state: HomeViewState.State { viewState.state }

    var body: some View {
        NavigationStack(path: $navigationState.path) {
            VStack(alignment: .leading, spacing: 16) {
                header()

                randomJoke()

                categories()
            }
            .padding(.horizontal)
            .navigationTitle("Home")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: MainCoordinator.Link.self) { link in
                switch link {
                case .category(let pathData):
                    CategoryView(viewState: pathData.viewState)
                }
            }
        }
    }
}


// MARK: - Subviews

private extension HomeView {

    func header() -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    Text("Chuck Norris Jokes")
                        .appTitle1()

                    Spacer()

                    HStack {
                        Spacer()
                        Text("Powered by")
                            .appBodyTextSmall()
                    }
                }

                Image("chucknorris_logo")
                    .scale(height: 50)
            }
            .fixedSize(horizontal: false, vertical: true)

            Divider()
                .padding(.top, 8)
        }
    }

    func randomJoke() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Random Joke")
                    .appTitle2()

                Spacer()

                Image(systemName: "arrow.clockwise")
                    .foregroundStyle(state.refreshButtonDisabled ? .appOnSurfaceDisabled : .appTextLink)
                    .disabled(state.refreshButtonDisabled)
                    .onTapGesture {
                        viewState.send(action: .refreshButtonPressed)
                    }
            }

            error(message: state.randomJokeError)

            Group {
                if let randomJoke = state.randomJoke {
                    Text(randomJoke)
                        .appBodyText()
                        .italic()
                }
                else {
                    Text("This is dummy text to provide something to be redacted.")
                        .redacted(reason: .placeholder)
                }
            }
            .padding(.horizontal)
        }
    }

    func categories() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Categories")
                .appTitle2()

            error(message: state.categoriesError)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let categoryNames = state.categories {
                        ForEach(categoryNames, id: \.self) { categoryName in
                            HomeCategoryListRow(categoryName: categoryName)
                                .onTapGesture {
                                    viewState.send(action: .categorySelected(name: categoryName))
                                }
                        }
                    }
                    else {
                        Group {
                            Text("Category 1")
                            Text("Category 2")
                            Text("Category 3")
                        }
                        .redacted(reason: .placeholder)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    func error(message: String?) -> some View {
        if let message = message {
            Text(message)
                .appTextError()
        }
        else {
            EmptyView()
        }
    }
}


// MARK: - Previews

#Preview("Initial State") {
    return HomeView(viewState: HomeViewState())
        .environmentObject(NavigationState())
        .preferredColorScheme(.light)
}

#Preview("Joke Loaded") {
    let viewState = HomeViewState()
    return HomeView(viewState: viewState)
        .task {
            let result = GetRandomJokeResult.success(randomJoke)
            viewState.reduce(with: .getRandomJokeResult(result))
        }
        .environmentObject(NavigationState())
        .preferredColorScheme(.light)
}

#Preview("Categories Loaded") {
    let viewState = HomeViewState()
    return HomeView(viewState: viewState)
        .task {
            let result = GetCategoriesResult.success(categoryNames)
            viewState.reduce(with: .getCategoriesResult(result))
        }
        .environmentObject(NavigationState())
        .preferredColorScheme(.light)
}

#Preview("Ready") {
    let viewState = HomeViewState()
    return HomeView(viewState: viewState)
        .task {
            let jokeResult = GetRandomJokeResult.success(randomJoke)
            let categoriesResult = GetCategoriesResult.success(categoryNames)
            viewState.reduce(with: .getRandomJokeResult(jokeResult))
            viewState.reduce(with: .getCategoriesResult(categoriesResult))
        }
        .environmentObject(NavigationState())
        .preferredColorScheme(.light)
}

#Preview("Errors") {
    let viewState = HomeViewState()
    return HomeView(viewState: viewState)
        .task {
            let jokeError = AppUrlSession.RequestError.serverResponse(code: 404)
            let categoriesError = AppUrlSession.RequestError.serverResponse(code: 404)
            let jokeResult = GetRandomJokeResult.failure(jokeError)
            let categoriesResult = GetCategoriesResult.failure(categoriesError)
            viewState.reduce(with: .getRandomJokeResult(jokeResult))
            viewState.reduce(with: .getCategoriesResult(categoriesResult))
        }
        .environmentObject(NavigationState())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    return HomeView(viewState: HomeViewState())
        .environmentObject(NavigationState())
        .preferredColorScheme(.dark)
}

#Preview("Dark Errors") {
    let viewState = HomeViewState()
    return HomeView(viewState: viewState)
        .task {
            let jokeError = AppUrlSession.RequestError.serverResponse(code: 404)
            let categoriesError = AppUrlSession.RequestError.serverResponse(code: 404)
            let jokeResult = GetRandomJokeResult.failure(jokeError)
            let categoriesResult = GetCategoriesResult.failure(categoriesError)
            viewState.reduce(with: .getRandomJokeResult(jokeResult))
            viewState.reduce(with: .getCategoriesResult(categoriesResult))
        }
        .environmentObject(NavigationState())
        .preferredColorScheme(.dark)
}

fileprivate let randomJoke = "Chuck Norris can kill you with a headshot using a shotgun from across the map on call of duty."
fileprivate let categoryNames = ["animal","career","celebrity","dev","explicit","fashion","food","history","money","movie","music","political","religion","science","sport","travel"]

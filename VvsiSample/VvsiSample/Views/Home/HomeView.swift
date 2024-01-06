//  Copyright © 2024 Rob Vander Sloot
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewState: HomeViewState

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                header()

                randomJoke()

                categories()
            }
            .padding(.horizontal)
            .navigationTitle("Home")
            .toolbar(.hidden, for: .navigationBar)
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
        VStack(alignment: .leading) {
            HStack {
                Text("Random Joke")
                    .appTitle2()

                Spacer()

                Image(systemName: "arrow.clockwise")
                    .foregroundStyle(viewState.refreshButtonDisabled ? .appOnSurfaceDisabled : .appTextLink)
                    .padding(4)
                    .onTapGesture {
                        viewState.on(event: .refreshButtonPressed)
                    }
                    .disabled(viewState.refreshButtonDisabled)
            }

            error(message: viewState.randomJokeError)

            Group {
                if let randomJoke = viewState.randomJoke {
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
        VStack(alignment: .leading) {
            Text("Categories")
                .appTitle2()

            error(message: viewState.categoriesError)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let categoryNames = viewState.categories {
                        ForEach(categoryNames, id: \.self) { categoryName in
                            NavigationLink(value: categoryName) {
                                HomeCategoryListRow(categoryName: categoryName)
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
        .navigationDestination(for: String.self) { selectedCategory in
            CategoryView(selectedCategory: selectedCategory)
        }
    }

    func error(message: String?) -> (some View)? {
        guard let message = message else {
            return AnyView(EmptyView())
        }

        return AnyView(Text(message)
            .foregroundStyle(.appTextError)
            .appBodyTextSmall())
    }
}


// MARK: - Previews

#Preview("Initial State") {
    return HomeView(viewState: HomeViewState())
        .preferredColorScheme(.light)
}

#Preview("Joke Loaded") {
    let viewState = HomeViewState()
    return HomeView(viewState: viewState)
        .task {
            await viewState.set(state: .updateRandomJoke(randomJoke))
        }
        .preferredColorScheme(.light)
}

#Preview("Categories Loaded") {
    let viewState = HomeViewState()
    return HomeView(viewState: viewState)
        .task {
            await viewState.set(state: .updateCategories(categoryNames))
        }
        .preferredColorScheme(.light)
}

#Preview("Ready") {
    let viewState = HomeViewState()
    return HomeView(viewState: viewState)
        .task {
            await viewState.set(state: .updateRandomJoke(randomJoke))
            await viewState.set(state: .updateCategories(categoryNames))
        }
        .preferredColorScheme(.light)
}

#Preview("Errors") {
    let viewState = HomeViewState()
    return HomeView(viewState: viewState)
        .task {
            await viewState.set(state: .updateRandomJoke(nil, errorMessage: "There was a random joke error."))
            await viewState.set(state: .updateCategories(nil, errorMessage: "There was a category error."))
        }
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    return HomeView(viewState: HomeViewState())
        .preferredColorScheme(.dark)
}

fileprivate let randomJoke = "Chuck Norris can kill you with a headshot using a shotgun from across the map on call of duty."
fileprivate let categoryNames = ["animal","career","celebrity","dev","explicit","fashion","food","history","money","movie","music","political","religion","science","sport","travel"]

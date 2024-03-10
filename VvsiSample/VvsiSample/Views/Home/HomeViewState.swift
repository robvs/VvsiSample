//  Copyright © 2024 Rob Vander Sloot
//

import Combine

/// Manage view state for the Home screen.
class HomeViewState: ViewState<HomeViewState.State> {

    /// Encapsulation of values that drive the dynamic elements of the associated view.
    ///
    /// The default values indicate the intended initial state.
    struct State: Equatable {
        var randomJoke: String?
        var randomJokeError: String?
        var categories: [String]?
        var categoriesError: String?
        var refreshButtonDisabled: Bool = true
    }

    init() {
        super.init(initialState: State())
    }
}


// MARK: - State Conformance to ViewStateReducible

extension HomeViewState.State: ViewStateReducible {

    // MARK: Actions & Effects

    /// Actions generated by the view or by the system.
    /// Typically consumed by the associated view interactor or navigation coordinator.
    enum Action {
        case refreshButtonPressed
        case categorySelected(name: String)
    }

    /// Items that designates how the view state should change, usually
    /// the result of an `Action`.
    enum Effect: Equatable {
        /// Indicates that the random joke is being fetched.
        case loadingRandomJoke

        /// Indicates that retrieval of the random joke is complete.
        case getCategoriesResult(GetCategoriesResult)

        /// Indicates that retrieval of the random joke is complete.
        case getRandomJokeResult(GetRandomJokeResult)
    }

    // MARK: Reducer

    /// Handle changes from the current state to the next state.
    mutating func reduce(with effect: Effect) {
        switch effect {
        case .loadingRandomJoke:
            refreshButtonDisabled = true
            randomJoke = nil
            randomJokeError = nil

        case .getRandomJokeResult(let result):
            refreshButtonDisabled = false

            switch result {
            case .success(let joke):
                randomJoke = joke
                randomJokeError = nil
            case .failure(let error):
                randomJoke = ""
                randomJokeError = error.localizedDescription
            }

        case .getCategoriesResult(let result):
            switch result {
            case .success(let categories):
                self.categories = categories
                categoriesError = nil
            case .failure(let error):
                categories = []
                categoriesError = error.localizedDescription
            }
        }
    }
}

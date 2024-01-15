//  Copyright © 2024 Rob Vander Sloot
//

import Combine
import OSLog
import SwiftUI

typealias HomeViewStateBase = ViewStateBase<HomeViewState.State, 
                                            HomeViewState.Event>

/// Manage view state for the Home screen.
class HomeViewState: HomeViewStateBase {

    // MARK: State definition

    /// Available view states.
    enum State: Equatable {
        /// Indicates that one or more items are being loaded.
        case loading(includesRandomJoke: Bool, includesCategories: Bool)

        /// Indicates that loading is complete and the view is ready.
        case ready
    }

    // MARK: Events

    /// Events emitted by the view & republished/forwarded by this view state.
    enum Event {
        case refreshButtonPressed
        case categorySelected(name: String)
    }

    // MARK: Published values
    // use `private (set)` to enforce use of `set(state:)` to change published values.

    @Published private (set) var randomJoke: String?
    @Published private (set) var randomJokeError: String?
    @Published private (set) var categories: [String]?
    @Published private (set) var categoriesError: String?
    @Published private (set) var refreshButtonDisabled: Bool = true

    // MARK: Object lifecycle

    init() {
        let initialState: State = .loading(includesRandomJoke: true, includesCategories: true)
        super.init(with: initialState, updateAction: Self.updateProperties)
    }
}


// MARK: - Public methods

extension HomeViewState {

    /// Update the random joke to the given value or set the random joke's error message.
    ///
    /// This may result in a change to `currentState`.
    /// - parameters:
    ///  - randomJoke: The joke to be displayed. If `errorMessage` is nil, this should not be.
    ///  - errorMessage: The error message to be displayed.
    @MainActor
    func update(randomJoke: String?, errorMessage: String? = nil) async {
        self.randomJoke = errorMessage == nil ? randomJoke : nil
        randomJokeError = errorMessage

        if currentState.isLoadingCategories {
            // the random joke is finished loading but categories aren't.
            await set(state: .loading(includesRandomJoke: false, includesCategories: true))
        }
        else {
            await set(state: .ready)
        }
    }

    /// Update the categories to the given value or set the categories' error message.
    ///
    /// This may result in a change to `currentState`.
    /// - parameters:
    ///  - categories: The categories to be displayed. If `errorMessage` is nil, this should not be.
    ///  - errorMessage: The error message to be displayed.
    @MainActor
    func update(categories: [String]?, errorMessage: String? = nil) async {
        self.categories = errorMessage == nil ? categories : nil
        categoriesError = errorMessage

        if currentState.isLoadingRandomJoke {
            // categories are finished loading but the random joke isn't.
            await set(state: .loading(includesRandomJoke: true, includesCategories: false))
        }
        else {
            await set(state: .ready)
        }
    }
}


// MARK: - Private Helpers

private extension HomeViewState {

    /// Update the dynamic (e.g. Published) view properties.
    /// This function is called from the base class whenever the state changes.
    ///
    /// What makes this tricky is that it is used by `init()` to set the default state and
    /// by `set(state:)` to update the state. When called from `set(state:)`,
    /// this must be called on the `main` queue, but we don't want `init()` to require
    /// the `main` queue.
    static func updateProperties(on viewState: HomeViewStateBase,
                                 for state: State) {
        guard let viewState = viewState as? HomeViewState else {
            // the given view state could not be converted to the expected type.
            // This should never happen.
            Logger.view.fault("viewState could not be converted to HomeViewState.")
            return
        }

        switch state {
        case .loading(let includesRandomJoke, let includesCategories):
            if includesRandomJoke {
                viewState.randomJoke = nil
                viewState.randomJokeError = nil
                viewState.refreshButtonDisabled = true
            }

            if includesCategories {
                viewState.categories = nil
                viewState.categoriesError = nil
            }

        case .ready:
            viewState.refreshButtonDisabled = false
        }
    }
}


// MARK: - State Helpers

extension HomeViewState.State {

    var isLoadingRandomJoke: Bool {
        return if case .loading(let includesRandomJoke, _) = self {
            includesRandomJoke
        }
        else {
            false
        }
    }

    var isLoadingCategories: Bool {
        return if case .loading(_, let includesCategories) = self {
            includesCategories
        }
        else {
            false
        }
    }
}

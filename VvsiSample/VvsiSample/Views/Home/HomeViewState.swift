//  Copyright © 2024 Rob Vander Sloot
//

import Combine
import SwiftUI

typealias HomeViewStateBase = ViewStateBase<HomeViewState.State, 
                                            HomeViewState.Event>

class HomeViewState: HomeViewStateBase {

    // MARK: State definition

    /// Available view states.
    enum State: Equatable {
        case loading(includesRandomJoke: Bool, includesCategories: Bool)
        case updateRandomJoke(joke: String)
        case updateCategories(categories: [String])
        case ready
    }

    // MARK: Events

    /// Events emitted by the view & republished/forwarded by this view state.
    enum Event {
        case refreshButtonPressed
    }

    // MARK: Published values

    @Published private (set) var randomJoke: String? = nil   // nil indicates loading
    @Published private (set) var categories: [String]? = nil // nil indicates loading
    @Published private (set) var refreshButtonDisabled: Bool = true

    // MARK: Object lifecycle

    init() {
        let initialState: State = .loading(includesRandomJoke: true, includesCategories: true)
        super.init(with: initialState, updateAction: Self.updateProperties)
    }

    // MARK: ViewStateBase overrides

    /// This override captures `updateRandomJoke` and `updateCategories` states
    /// in order to update the respective properties without changing `currentState` until
    /// loading of both is complete.
    @MainActor
    override func set(state: ViewStateBase<State, Event>.State) async {
        switch state {
        case .updateRandomJoke(let joke):
            randomJoke = joke
            if areCategoriesLoading == false {
                await super.set(state: .ready)
            }

        case .updateCategories(let categories):
            self.categories = categories
            if isRandomJokeLoading == false {
                await super.set(state: .ready)
            }

        default:
            await super.set(state: state)
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
            return
        }

        switch state {
        case .loading(let includesRandomJoke, let includesCategories):
            if includesRandomJoke {
                viewState.randomJoke = nil
            }

            if includesCategories {
                viewState.categories = nil
            }

        case .updateRandomJoke:
            // this function should never be called with this state
            break

        case .updateCategories:
            // this function should never be called with this state
            break

        case .ready:
            viewState.refreshButtonDisabled = false
        }
    }

    var isRandomJokeLoading: Bool  { randomJoke == nil }
    var areCategoriesLoading: Bool { categories == nil }
}

//  Copyright © 2024 Rob Vander Sloot
//

import OSLog
import SwiftUI

typealias CategoryViewStateBase = ViewStateBase<CategoryViewState.State,
                                                CategoryViewState.Event>

/// Manage view state for the Category screen.
class CategoryViewState: CategoryViewStateBase {

    // MARK: State definition

    /// Available view states.
    enum State: Equatable {
        /// Indicates that one or more items are being loaded.
        case loading

        /// Indicates that an error occurred.
        case error(message: String)

        /// Indicates that loading is complete and the view is ready.
        case ready(categoryJokes: [String])
    }

    // MARK: Events

    /// Events emitted by the view & republished/forwarded by this view state.
    enum Event {
        case refreshButtonPressed
    }

    // MARK: Published values
    // use `private (set)` to enforce use of `set(state:)` to change published values.

    @Published private (set) var categoryJokes: [String] = []
    @Published private (set) var errorMessage: String?
    @Published private (set) var refreshButtonDisabled: Bool = true

    // MARK: Properties

    // note: even though this is used by the view, it is not `@Published`
    //       because its value does not change.
    let categoryName: String

    // MARK: Object lifecycle

    init(categoryName: String) {
        self.categoryName = categoryName
        super.init(with: .loading, updateAction: Self.updateProperties)
    }
}


// MARK: - Private Helpers

private extension CategoryViewState {

    /// Update the dynamic (e.g. Published) view properties.
    /// This function is called from the base class whenever the state changes.
    ///
    /// What makes this tricky is that it is used by `init()` to set the default state and
    /// by `set(state:)` to update the state. When called from `set(state:)`,
    /// this must be called on the `main` queue, but we don't want `init()` to require
    /// the `main` queue.
    static func updateProperties(on viewState: CategoryViewStateBase,
                                 for state: State) {
        guard let viewState = viewState as? CategoryViewState else {
            // the given view state could not be converted to the expected type.
            // This should never happen.
            Logger.view.fault("viewState could not be converted to CategoryViewState.")
            return
        }

        switch state {
        case .loading:
            viewState.categoryJokes = []
            viewState.errorMessage = nil
            viewState.refreshButtonDisabled = true

        case .error(let message):
            viewState.errorMessage = message
            viewState.refreshButtonDisabled = false

        case .ready(let categoryJokes):
            viewState.categoryJokes = categoryJokes
            viewState.errorMessage = nil
            viewState.refreshButtonDisabled = false
        }
    }
}

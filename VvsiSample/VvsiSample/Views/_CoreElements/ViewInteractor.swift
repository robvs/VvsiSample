//  Copyright © 2024 Rob Vander Sloot
//

import Combine
import OSLog

/// Base class for view interactors, which handle interactions between a view and the
/// rest of the system.
class ViewInteractor<ViewState, NavigationEvent>: NavigationPathable {

    /// Manages the dynamic elements of a view as well as user interactions.
    let viewState: ViewState

    /// Publishes navigation events.
    let navigationEventPublisher: AnyPublisher<NavigationEvent, Never>

    // MARK: Object lifecycle

    /// Initialize this instance with the given values.
    /// - parameters:
    ///  - viewState: The view state associated with this interactor. It is used to drive view changes.
    ///  - navigationEventPublisher: Publishes navigation notifications.
    init(viewState: ViewState,
         navigationEventPublisher: AnyPublisher<NavigationEvent, Never>) {
        self.viewState = viewState
        self.navigationEventPublisher = navigationEventPublisher
    }
}

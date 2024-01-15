//  Copyright © 2024 Rob Vander Sloot
//

import Combine
import OSLog

/// Base class for view interactors, which handle interactions between a view and the
/// rest of the system.
class ViewInteractorBase<ViewState, NavigationEvent>: NavigationPathable {

    /// Manages the dynamic elements of a view as well as user interactions.
    let viewState: ViewState

    /// Publishes navigation notifications.
    let navigationEventPublisher: AnyPublisher<NavigationEvent, Never>

    init(viewState: ViewState,
         navigationEventPublisher: AnyPublisher<NavigationEvent, Never>) {
        self.viewState = viewState
        self.navigationEventPublisher = navigationEventPublisher
    }
}


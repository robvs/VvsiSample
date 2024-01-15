//  Copyright © 2024 Rob Vander Sloot
//

import Combine
import OSLog

/// Base class for view interactors, which handle interactions between a view and the
/// rest of the system.
class ViewInteractorBase<ViewState, NavigationEvent>: ViewInteracting {

    let viewState: ViewState

    /// Publishes navigation notifications.
    let navigationEventPublisher: AnyPublisher<NavigationEvent, Never>
    private let navigationEventSubject: PassthroughSubject<NavigationEvent, Never>

    init(viewState: ViewState) {
        self.viewState = viewState

        navigationEventSubject = PassthroughSubject<NavigationEvent, Never>()
        navigationEventPublisher = navigationEventSubject.eraseToAnyPublisher()
    }
}


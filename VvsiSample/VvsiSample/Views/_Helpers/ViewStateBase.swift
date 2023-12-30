//  Copyright © 2024 Rob Vander Sloot
//

import Combine

/// Events that can be emitted by a view state relating to the view's lifecycle.
enum ViewLifeCycleEvent {
    case viewWillAppear
    case viewDidDisappear
}

/// Base class for view state objects. Provides functionality that is common to all view states.
class ViewStateBase<S, ET>: ObservableObject {

    // type-aliases for the ViewStateProtocol's associated types
    typealias State = S
    typealias EventType = ET
    typealias UpdateAction = (ViewStateBase<S, ET>, S) -> Void

    // MARK: Public properties

    /// Publishes view life cycle events (i.e. viewDidLoad, viewWillAppear, etc.)
    let viewLifeCycleEventPublisher: AnyPublisher<ViewLifeCycleEvent, Never>

    /// Publishes view events - typically originating from a user action such as a button press.
    let eventPublisher: AnyPublisher<EventType, Never>

    /// Publishes view state change events.
    let stateChangePublisher: AnyPublisher<State, Never>

    /// The view's current state.
    private (set) var currentState: State

    // MARK: private properties

    private (set) var didLoad = false
    private let updateAction: (ViewStateBase<S, ET>, S) -> Void
    private var cancellables: [Combine.AnyCancellable] = []

    // event subjects that are used to send new events to the event publishers.
    private let viewLifeCycleEventSubject: PassthroughSubject<ViewLifeCycleEvent, Never>
    private let eventSubject: PassthroughSubject<EventType, Never>
    private let stateChangeSubject: PassthroughSubject<State, Never>

    // MARK: Alert handling

    /// Indicates whether the alert should appear
    /// Note that the view must include `.alert(isPresented:)`.
    @Published var shouldShowAlert: Bool = false

    /// When an alert needs to be displayed, this is set to the desired alert type.
    /// Note that the view must include `.alert(isPresented:)`.
    var alertType: AppAlert.AlertType = .none {
        didSet {
            // note that `shouldShowAlert` is not set to false here because
            // that is handled by the view.
            if alertType != .none {
                shouldShowAlert = true
            }
        }
    }

    // MARK: View lifecycle

    init(with state: State, updateAction: @escaping UpdateAction) {
        viewLifeCycleEventSubject = PassthroughSubject<ViewLifeCycleEvent, Never>()
        viewLifeCycleEventPublisher = viewLifeCycleEventSubject.eraseToAnyPublisher()

        eventSubject = PassthroughSubject<EventType, Never>()
        eventPublisher = eventSubject.eraseToAnyPublisher()

        stateChangeSubject = PassthroughSubject<State, Never>()
        stateChangePublisher = stateChangeSubject.eraseToAnyPublisher()

        currentState = state
        self.updateAction = updateAction
        updateAction(self, state)
    }

    /// Handle the given view lifecycle event and republish to listeners via `viewLifeCycleEventPublisher`.
    ///
    /// This is expected to be called by the view when a lifecycle event happens. For example:
    /// `.task { viewState.on(viewLifecycleEvent: .viewWillAppear) }`
    /// `.onDisappear { viewModel.viewLifecycleInput.event.onNext(.viewWillDisappear) }`
    ///
    /// This can be overridden for custom handling.
    func on(viewLifecycleEvent: ViewLifeCycleEvent) {
        viewLifeCycleEventSubject.send(viewLifecycleEvent)
    }

    /// Handle the given view event and republish to listeners via `eventPublisher`.
    ///
    /// This is expected to be called by the view when an event such as a button press happens.
    /// This can be overridden for custom handling.
    func on(event: EventType) {
        eventSubject.send(event)
    }

    /// Handle updates to the view state - e.g. handle changing the appearance of the view.
    ///
    /// This is isolated to `MainActor` to ensure that other objects call it from the main thread.
    @MainActor
    func set(state: State) async {
        updateAction(self, state)
        currentState = state

        stateChangeSubject.send(currentState)
    }
}


// MARK: - Private Helpers

private extension ViewStateBase {

    func listenForInputs() {
        $shouldShowAlert.sink { [weak self] shouldShow in
            // clear `alertType` after the user has dismissed the alert.
            if !shouldShow {
                self?.alertType = .none
            }
        }
        .store(in: &cancellables)
    }
}

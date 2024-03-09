//  Copyright © 2024 Rob Vander Sloot
//

import Combine

/// Events that can be emitted by a view relating to it's lifecycle.
///
/// The view emits lifecycle events like this:
/// `.task { viewState.send(lifecycleEvent: .viewWillAppear) }`
/// `.onDisappear { viewState.send(lifecycleEvent: .viewDidDisappear) }`
enum ViewLifecycleEvent {
    case viewWillAppear
    case viewDidDisappear
}

/// Base class for view state objects, which handles interactions with a view.
///
/// `State` A specific view's `State` type that conforms to `ViewStateReducible`.
///
/// The view emits input actions like this:
/// `viewState.send(action: .okButtonPressed)`
class ViewState<State: ViewStateReducible>: ObservableObject {

    /// Define a type for `ViewStateReducible`'s associated type.
    typealias Action = State.Action
    typealias Effect = State.Effect

    // MARK: Public properties

    /// Object who's properties drive the dynamic elements of the view.
    @Published private (set) var state: State

    /// Publishes view lifecycle events (i.e. viewWillAppear, viewDidDisappear)
    let viewLifecycleEventPublisher: AnyPublisher<ViewLifecycleEvent, Never>

    /// Publishes view actions - typically originating from a user action such as a button press.
    let actionPublisher: AnyPublisher<Action, Never>

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

    // MARK: private properties

    private var cancellables: [Combine.AnyCancellable] = []

    // event subjects that are used to send new events to the event publishers.
    private let viewLifecycleEventSubject: PassthroughSubject<ViewLifecycleEvent, Never>
    private let actionSubject: PassthroughSubject<Action, Never>

    // MARK: View lifecycle

    init(initialState: State) {
        state = initialState

        // configure event subjects and publishers.
        viewLifecycleEventSubject = PassthroughSubject<ViewLifecycleEvent, Never>()
        viewLifecycleEventPublisher = viewLifecycleEventSubject.eraseToAnyPublisher()

        actionSubject = PassthroughSubject<Action, Never>()
        actionPublisher = actionSubject.eraseToAnyPublisher()

        listenForInputs()
    }

    /// Handle changes from the current state to the next state.
    ///
    /// Note that callers can't use `viewState.state.reduce()` because `state`
    /// is defined as `private (set)` in order to ensure that all state mutations are
    /// routed through this object.
    func reduce(with effect: Effect) {
        state.reduce(with: effect)
    }

    /// Handle the given view lifecycle event and republish to listeners via `viewLifecycleEventPublisher`.
    ///
    /// This is expected to be called by the view when a lifecycle event happens. For example:
    /// `.task { viewState.send(lifecycleEvent: .viewWillAppear) }`
    /// `.onDisappear { viewState.send(lifecycleEvent: .viewDidDisappear) }`
    ///
    /// This can be overridden for custom handling.
    func send(lifecycleEvent: ViewLifecycleEvent) {
        viewLifecycleEventSubject.send(lifecycleEvent)
    }

    /// Handle the given action and republish to listeners via `actionPublisher`.
    ///
    /// This is expected to be called by the view when an event such as a button press happens.
    /// This can be overridden for custom handling.
    func send(action: Action) {
        actionSubject.send(action)
    }
}


// MARK: - Private Helpers

private extension ViewState {

    func listenForInputs() {
        $shouldShowAlert
            .sink { [weak self] shouldShow in
                // clear `alertType` after the user has dismissed the alert.
                if !shouldShow {
                    self?.alertType = .none
                }
            }
            .store(in: &cancellables)
    }
}

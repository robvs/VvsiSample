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
class ViewState<State: ViewStateReducible>: ObservableObject {

    /// `ViewStateReducible`'s associated types, which are defined by the
    /// derived view state.
    typealias Action = State.Action
    typealias Effect = State.Effect

    // MARK: Public properties

    /// Object who's properties drive the dynamic elements of the view.
    /// `private (set)` is used to help ensure that state changes
    /// are always funneled through `ViewState.reduce()`.
    @Published private (set) var state: State

    /// Publishes view lifecycle events (i.e. viewWillAppear, viewDidDisappear)
    let viewLifecycleEventPublisher: AnyPublisher<ViewLifecycleEvent, Never>

    /// Publishes view actions (i.e. okButtonPressed)
    let actionPublisher: AnyPublisher<Action, Never>

    // MARK: Alert handling

    /// Indicates whether the alert should appear
    ///
    /// Note that this is set to true when `alertType`is set and it is cleared
    /// automatically when the alert is dismissed. The view must include:
    /// `.alert(isPresented: $viewState.shouldShowAlert) {}`.
    @Published var shouldShowAlert: Bool = false

    /// When an alert needs to be displayed, this is set to the desired alert type.
    var alertType: AppAlert.AlertType = .none {
        didSet {
            // note that `shouldShowAlert` is not set to false here because
            // that is handled by the view when the alert is dismissed.
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

    // MARK: Object lifecycle
    
    /// Create a new instance with the given initial state.
    /// - Parameter initialState: The initial state of the view.
    init(initialState: State) {
        state = initialState

        // configure event subjects and publishers.
        viewLifecycleEventSubject = PassthroughSubject<ViewLifecycleEvent, Never>()
        viewLifecycleEventPublisher = viewLifecycleEventSubject.eraseToAnyPublisher()

        actionSubject = PassthroughSubject<Action, Never>()
        actionPublisher = actionSubject.eraseToAnyPublisher()

        listenForInputs()
    }

    // MARK: Public methods
    
    /// Handle changes from the current state to the next state.
    ///
    /// Note that callers can not use `viewState.state.reduce()` because `state`
    /// is defined as `private (set)` in order to ensure that all state mutations are
    /// routed through this object.
    /// - Parameter effect: Directive of how the state should change.
    @MainActor
    func reduce(with effect: Effect) {
        state.reduce(with: effect)
    }
    
    /// Handle the given view lifecycle event and publish to listeners via `viewLifecycleEventPublisher`.
    ///
    /// This is expected to be called by the view when a lifecycle event happens. For example:
    /// `.task { viewState.send(lifecycleEvent: .viewWillAppear) }`
    /// `.onDisappear { viewState.send(lifecycleEvent: .viewDidDisappear) }`
    ///
    /// This can be overridden for custom handling.
    /// - Parameter lifecycleEvent: The event that has occurred.
    func send(lifecycleEvent: ViewLifecycleEvent) {
        viewLifecycleEventSubject.send(lifecycleEvent)
    }
    
    /// Handle the given action and publish to listeners via `actionPublisher`.
    ///
    /// This is expected to be called by the view when an event such as a button press happens.
    /// Actions typically lead to an effect, which is handled by `reduce(with: effect)`.
    /// This can be overridden for custom handling.
    /// - Parameter action: The action that has occurred.
    func send(action: Action) {
        actionSubject.send(action)
    }
}


// MARK: - Private Helpers

private extension ViewState {

    func listenForInputs() {
        $shouldShowAlert
            .sink { [weak self] shouldShow in
                if !shouldShow {
                    // `shouldShowAlert` is bound to the alert, which sets it
                    // to false when the alert is dismissed. Now we need to
                    // update `alertType` to keep these values synchronized.
                    self?.alertType = .none
                }
            }
            .store(in: &cancellables)
    }
}

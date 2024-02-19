//  Copyright © 2024 Rob Vander Sloot
//

import Combine

/// Events that can be emitted by a view state relating to the view's lifecycle.
enum ViewLifecycleEvent {
    case viewWillAppear
    case viewDidDisappear
}

/// Base class for view state objects, which are objects that drive the dynamic
/// elements of a view.
///
/// `State` is defined by a subclass to represent specific states.
/// `Event` is defined by a subclass to represent event that can be emitted by the view.
///
/// The view emits input event like this:
/// `.onAppear { viewState.on(viewLifecycleEvent: .viewWillAppear) }`
class ViewState<State, Event>: ObservableObject {

    // type-alias helper
    typealias UpdateAction = (ViewState<State, Event>, State) -> Void

    // MARK: Public properties

    /// Publishes view lifecycle events (i.e. viewWillAppear, viewDidDisappear)
    let viewLifecycleEventPublisher: AnyPublisher<ViewLifecycleEvent, Never>

    /// Publishes view events - typically originating from a user action such as a button press.
    let eventPublisher: AnyPublisher<Event, Never>

    /// The view's current state.
    private (set) var currentState: State

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

    private let updateAction: UpdateAction
    private var cancellables: [Combine.AnyCancellable] = []

    // event subjects that are used to send new events to the event publishers.
    private let viewLifecycleEventSubject: PassthroughSubject<ViewLifecycleEvent, Never>
    private let eventSubject: PassthroughSubject<Event, Never>

    // MARK: View lifecycle

    init(with state: State, updateAction: @escaping UpdateAction) {
        // configure event subjects and publishers.
        viewLifecycleEventSubject = PassthroughSubject<ViewLifecycleEvent, Never>()
        viewLifecycleEventPublisher = viewLifecycleEventSubject.eraseToAnyPublisher()

        eventSubject = PassthroughSubject<Event, Never>()
        eventPublisher = eventSubject.eraseToAnyPublisher()

        // set the initial state.
        currentState = state
        self.updateAction = updateAction
        updateAction(self, state)

        listenForInputs()
    }

    /// Handle the given view lifecycle event and republish to listeners via `viewLifecycleEventPublisher`.
    ///
    /// This is expected to be called by the view when a lifecycle event happens. For example:
    /// `.task { viewState.on(viewLifecycleEvent: .viewWillAppear) }`
    /// `.onDisappear { viewModel.viewLifecycleInput.event.onNext(.viewWillDisappear) }`
    ///
    /// This can be overridden for custom handling.
    func on(viewLifecycleEvent: ViewLifecycleEvent) {
        viewLifecycleEventSubject.send(viewLifecycleEvent)
    }

    /// Handle the given view event and republish to listeners via `eventPublisher`.
    ///
    /// This is expected to be called by the view when an event such as a button press happens.
    /// This can be overridden for custom handling.
    func on(event: Event) {
        eventSubject.send(event)
    }

    /// Handle updates to the view state - e.g. handle changing the appearance of the view.
    ///
    /// This is isolated to `MainActor` to ensure that other objects call it from the main thread.
    @MainActor
    func set(state: State) async {
        updateAction(self, state)
        currentState = state
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

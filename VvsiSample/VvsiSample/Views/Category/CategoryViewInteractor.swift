//  Copyright © 2024 Rob Vander Sloot
//

import Combine
import OSLog

/// Handle interactions between the Category screen (e.g. `CategoryViewState`) and the backend.
class CategoryViewInteractor: ViewInteractor<CategoryViewAgent,
                                             CategoryViewInteractor.NavigationEvent> {

    static let jokeCount = 5

    // MARK: Navigation Events

    /// Navigation events that are emitted by this object. These are typically
    /// subscribed to and handled by a navigation coordinator.
    enum NavigationEvent {
        // the only navigation from this screen is the back button,
        // which is handled by the `NavigationStack`.
    }

    private let navigationEventSubject: PassthroughSubject<NavigationEvent, Never>

    // MARK: Properties

    private let session: AppUrlSessionHandling
    private var randomJokesTask: Task<(), Never>?
    private var cancellables: [AnyCancellable] = []

    // MARK: Object lifecycle

    init(viewAgent: CategoryViewAgent, session: AppUrlSessionHandling) {
        // initialize stored properties
        self.session = session
        navigationEventSubject = PassthroughSubject<NavigationEvent, Never>()

        // initialize base class
        super.init(viewState: viewAgent,
                   navigationEventPublisher: navigationEventSubject.eraseToAnyPublisher())

        // listen for events from the view state.
        listenForEvents()

        // initiate the api calls.
        startFetchOfRandomJokes(for: viewAgent.state.categoryName)
    }
}


// MARK: - Event Handling

private extension CategoryViewInteractor {

    func listenForEvents() {
        // listen for view lifecycle events.
        viewState.viewLifecycleEventPublisher
            .sink { [weak self] lifeCycleEvent in
                switch lifeCycleEvent {
                case .viewWillAppear:
                    // nothing to do
                    break

                case .viewDidDisappear:
                    // cancel async tasks
                    self?.cancelTasks()
                }
            }
            .store(in: &cancellables)

        // listen for user input events.
        viewState.actionPublisher
            .sink { action in
                Task { @MainActor [weak self] in
                    self?.handle(action: action)
                }
            }
            .store(in: &cancellables)
    }

    /// Handle the given user input event.
    @MainActor
    func handle(action: CategoryViewAgent.Action) {
        switch action {
        case .refreshButtonPressed:
            viewState.reduce(with: .loading)
            startFetchOfRandomJokes(for: viewState.state.categoryName)
        }
    }
}


// MARK: - Private Helpers

private extension CategoryViewInteractor {

    func startFetchOfRandomJokes(for category: String) {
        randomJokesTask = Task { @MainActor in
            let result: GetRandomJokesResult

            do {
                // fetch a set of random category jokes
                var jokes: [String] = []
                for _ in 0..<Self.jokeCount {
                    let jokeUrl = ChuckNorrisIoRequest.getRandomJoke(category: category).url
                    let joke: ChuckNorrisJoke = try await session.get(from: jokeUrl)
                    try Task.checkCancellation()

                    if !jokes.contains(where: { $0 == joke.value }) {
                        jokes.append(joke.value)
                    }
                }

                result = GetRandomJokesResult.success(jokes)
            }
            catch let requestError as AppUrlSession.RequestError {
                result = GetRandomJokesResult.failure(requestError)
            }
            catch _ as CancellationError {
                // nothing to do here. cancellation is normal (i.e. because the view disappeared).
                return
            }
            catch {
                result = GetRandomJokesResult.failure(AppUrlSession.RequestError.unexpected(error.localizedDescription))
            }

            Logger.view.trace("Fetch result: \(String(describing: result))")
            viewState.reduce(with: .getRandomJokesResult(result))
        }
    }

    func cancelTasks() {
        randomJokesTask?.cancel()
    }
}

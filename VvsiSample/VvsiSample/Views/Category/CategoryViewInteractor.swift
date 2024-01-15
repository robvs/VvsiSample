//  Copyright © 2024 Rob Vander Sloot
//

import Combine
import OSLog

/// Handle interactions between the Category screen (e.g. `CategoryViewState`) and the backend.
class CategoryViewInteractor: ViewInteractorBase<CategoryViewState, CategoryViewInteractor.NavigationEvent>,
                              ObservableObject {

    static let jokeCount = 5

    // MARK: Navigation Events

    /// Navigation events that are emitted by this object. These are typically
    /// subscribed to and handled by a navigation coordinator.
    enum NavigationEvent {
        case dismiss
    }

    private let navigationEventSubject: PassthroughSubject<NavigationEvent, Never>

    // MARK: Properties

    private let session: AppUrlSessionHandling
    private var randomJokesTask: Task<(), Never>?
    private var cancellables: [AnyCancellable] = []

    // MARK: Object life cycle

    init(viewState: CategoryViewState, session: AppUrlSessionHandling) {
        // initialize stored properties
        self.session = session
        navigationEventSubject = PassthroughSubject<NavigationEvent, Never>()

        // initialize base class
        super.init(viewState: viewState,
                   navigationEventPublisher: navigationEventSubject.eraseToAnyPublisher())

        // listen for events from the view state.
        listenForEvents()

        // initiate the api calls.
        startFetchOfRandomJokes(for: viewState.categoryName)
    }
}


// MARK: - Event Handling

private extension CategoryViewInteractor {

    func listenForEvents() {
        // listen for view life cycle events.
        viewState.viewLifeCycleEventPublisher
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
        viewState.eventPublisher
            .sink { event in
                Task { @MainActor [weak self] in
                    await self?.handle(event: event)
                }
            }
            .store(in: &cancellables)
    }

    /// Handle the given user input event.
    @MainActor
    func handle(event: CategoryViewState.Event) async {
        switch event {
        case .refreshButtonPressed:
            await viewState.set(state: .loading)
            startFetchOfRandomJokes(for: viewState.categoryName)
        }
    }
}


// MARK: - Private Helpers

private extension CategoryViewInteractor {

    func startFetchOfRandomJokes(for category: String) {
        randomJokesTask = Task { @MainActor in
            var jokes: [String] = []

            do {
                // fetch a set of random category jokes
                for _ in 0..<Self.jokeCount {
                    let jokeUrl = ChuckNorrisIoRequest.getRandomJoke(category: category).url
                    let joke: ChuckNorrisJoke = try await session.get(from: jokeUrl)
                    try Task.checkCancellation()

                    if !jokes.contains(where: { $0 == joke.value }) {
                        jokes.append(joke.value)
                    }
                }

                Logger.view.trace("Update Category view with: \(jokes)")
                await viewState.set(state: .ready(categoryJokes: jokes))
            }
            catch let requestError as AppUrlSession.RequestError {
                let errorMessage = "Retrieval of a random category joke failed (\(requestError.code))"
                await viewState.set(state: .error(message: errorMessage))
            }
            catch _ as CancellationError {
                // nothing to do here. cancellation is normal (i.e. because the view disappeared).
            }
            catch {
                let errorMessage = "An unexpected error occurred: (\(error.localizedDescription))"
                await viewState.set(state: .error(message: errorMessage))
            }
        }
    }

    func cancelTasks() {
        randomJokesTask?.cancel()
    }
}

//  Copyright © 2024 Rob Vander Sloot
//

import Combine
import OSLog

/// Handle interactions between the Home screen (e.g. `HomeViewState`) and the backend.
class CategoryViewInteractor: ViewInteractorBase<CategoryViewState, CategoryViewInteractor.NavigationEvent>,
                              ObservableObject {

    // MARK: Navigation Events

    /// Navigation events that are emitted by this object. These are typically
    /// subscribed to and handled by a navigation coordinator.
    enum NavigationEvent {
        case dismiss
    }

    // MARK: Properties

    private let session: AppUrlSessionHandling
    private var randomJokesTask: Task<(), Never>?
    private var cancellables: [AnyCancellable] = []

    // MARK: Object life cycle

    init(viewState: CategoryViewState, session: AppUrlSessionHandling) {
        // initialize stored properties
        self.session = session

        // initialize base class
        super.init(viewState: viewState)

        // listen for events from the view state.
        listenForEvents()

        // initiate the api calls.
        startFetchOfRandomJokes()
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
//            await viewState.set(state: .loading(includesRandomJoke: true,
//                                                includesCategories: viewState.currentState.isLoadingCategories))
            startFetchOfRandomJokes()
        }
    }
}


// MARK: - Private Helpers

private extension CategoryViewInteractor {

    func startFetchOfRandomJokes() {
        randomJokesTask = Task { @MainActor in
//            do {
//                let joke: ChuckNorrisJoke = try await session.get(from: ChuckNorrisIoRequest.getRandomJoke().url)
//                try Task.checkCancellation()
//                await viewState.update(randomJoke: joke.value)
//            }
//            catch let requestError as AppUrlSession.RequestError {
//                let errorMessage = "Retrieval of a random joke failed (\(requestError.code))"
//                await viewState.update(randomJoke: nil, errorMessage: errorMessage)
//            }
//            catch _ as CancellationError {
//                // nothing to do here. cancellation is normal (i.e. because the view disappeared).
//            }
//            catch {
//                let errorMessage = "An unexpected error occurred: (\(error.localizedDescription))"
//                await viewState.update(randomJoke: nil, errorMessage: errorMessage)
//            }
        }
    }

    func cancelTasks() {
        randomJokesTask?.cancel()
    }
}

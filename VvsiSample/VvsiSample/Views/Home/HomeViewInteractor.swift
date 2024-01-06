//  Copyright © 2024 Rob Vander Sloot
//

import Combine

/// Handle interactions between the Home screen (e.g. `HomeViewState`) and the backend.
class HomeViewInteractor: ObservableObject {

    let viewState: HomeViewState

    // MARK: Properties

    private let session: AppUrlSessionHandling
    private var randomJokeTask: Task<(), Never>?
    private var categoriesTask: Task<(), Never>?
    private var cancellables: [AnyCancellable] = []

    // MARK: Object life cycle

    init(viewState: HomeViewState, session: AppUrlSessionHandling) {
        self.viewState = viewState
        self.session = session

        listenForEvents()

        startFetchOfRandomJoke()
        startFetchOfCategories()
    }
}


// MARK: - Event Handling

private extension HomeViewInteractor {

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
            .sink { [weak self] event in
                self?.handle(event: event)
            }
            .store(in: &cancellables)
    }

    /// Handle the given user input event.
    func handle(event: HomeViewState.Event) {
        switch event {
        case .refreshButtonPressed:
            startFetchOfRandomJoke()
        }
    }
}


// MARK: - Private Helpers

private extension HomeViewInteractor {

    func startFetchOfRandomJoke() {
        randomJokeTask = Task { @MainActor in
            do {
                let joke: ChuckNorrisJoke = try await session.get(from: ChuckNorrisIoRequest.getRandomJoke().url)
                try Task.checkCancellation()
                await viewState.set(state: .updateRandomJoke(joke.value))
            }
            catch let requestError as AppUrlSession.RequestError {
                let errorMessage = "Retrieval of a random joke failed (\(requestError.code))"
                await viewState.set(state: .updateRandomJoke(nil, errorMessage: errorMessage))
            }
            catch _ as CancellationError {
                // nothing to do here. cancellation is normal (i.e. because the view disappeared).
            }
            catch {
                let errorMessage = "An unexpected error occurred: (\(error.localizedDescription))"
                await viewState.set(state: .updateRandomJoke(nil, errorMessage: errorMessage))
            }
        }
    }

    func startFetchOfCategories() {
        categoriesTask = Task { @MainActor in
            do {
                let categories: [String] = try await session.get(from: ChuckNorrisIoRequest.getCategories.url)
                try Task.checkCancellation()
                await viewState.set(state: .updateCategories(categories))
            }
            catch let requestError as AppUrlSession.RequestError {
                let errorMessage = "Retrieval of a categories failed (\(requestError.code))"
                await viewState.set(state: .updateCategories(nil, errorMessage: errorMessage))
            }
            catch _ as CancellationError {
                // nothing to do here. cancellation is normal (i.e. because the view disappeared).
            }
            catch {
                let errorMessage = "An unexpected error occurred: (\(error.localizedDescription))"
                await viewState.set(state: .updateCategories(nil, errorMessage: errorMessage))
            }
        }
    }

    func cancelTasks() {
        randomJokeTask?.cancel()
        categoriesTask?.cancel()
    }
}

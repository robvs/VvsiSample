//  Copyright © 2024 Rob Vander Sloot
//

import Combine
import OSLog

/// Handle interactions between the Home screen (e.g. `HomeViewState`) and the backend.
class HomeViewInteractor: ViewInteractor<HomeViewState,
                                         HomeViewInteractor.NavigationEvent> {

    // MARK: Navigation Events

    /// Navigation events that are emitted by this object. These are typically
    /// subscribed to and handled by a navigation coordinator.
    enum NavigationEvent {
        case category(name: String)
    }

    private let navigationEventSubject: PassthroughSubject<NavigationEvent, Never>

    // MARK: Properties

    private let session: AppUrlSessionHandling
    private var randomJokeTask: Task<(), Never>?
    private var categoriesTask: Task<(), Never>?
    private var cancellables: [AnyCancellable] = []

    // MARK: Object lifecycle

    init(viewState: HomeViewState, session: AppUrlSessionHandling) {
        // initialize stored properties
        self.session = session
        navigationEventSubject = PassthroughSubject<NavigationEvent, Never>()

        // initialize base class
        super.init(viewState: viewState,
                   navigationEventPublisher: navigationEventSubject.eraseToAnyPublisher())

        // listen for events from the view state.
        listenForEvents()

        // initiate the api calls.
        startFetchOfRandomJoke()
        startFetchOfCategories()
    }
}


// MARK: - Event Handling

private extension HomeViewInteractor {

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
    func handle(action: HomeViewState.Action) {
        switch action {
        case .refreshButtonPressed:
            viewState.reduce(with: .loadingRandomJoke)
            startFetchOfRandomJoke()

        case .categorySelected(let categoryName):
            Logger.view.debug("Category selected: \(categoryName)")
            navigationEventSubject.send(.category(name: categoryName))
        }
    }
}


// MARK: - Private Helpers

private extension HomeViewInteractor {

    func startFetchOfRandomJoke() {
        randomJokeTask = Task { @MainActor in
            let result: GetRandomJokeResult

            do {
                let joke: ChuckNorrisJoke = try await session.get(from: ChuckNorrisIoRequest.getRandomJoke().url)
                try Task.checkCancellation()
                result = GetRandomJokeResult.success(joke.value)
            }
            catch let requestError as AppUrlSession.RequestError {
                result = GetRandomJokeResult.failure(requestError)
            }
            catch _ as CancellationError {
                // nothing to do here. cancellation is normal (i.e. because the view disappeared).
                return
            }
            catch {
                result = GetRandomJokeResult.failure(AppUrlSession.RequestError.unexpected(error.localizedDescription))
            }

            Logger.view.trace("Fetch result: \(String(describing: result))")
            viewState.reduce(with: .getRandomJokeResult(result))
        }
    }

    func startFetchOfCategories() {
        categoriesTask = Task { @MainActor in
            let result: GetCategoriesResult

            do {
                let categories: [String] = try await session.get(from: ChuckNorrisIoRequest.getCategories.url)
                try Task.checkCancellation()
                result = GetCategoriesResult.success(categories)
            }
            catch let requestError as AppUrlSession.RequestError {
                result = GetCategoriesResult.failure(requestError)
            }
            catch _ as CancellationError {
                // nothing to do here. cancellation is normal (i.e. because the view disappeared).
                return
            }
            catch {
                result = GetCategoriesResult.failure(AppUrlSession.RequestError.unexpected(error.localizedDescription))
            }

            viewState.reduce(with: .getCategoriesResult(result))
        }
    }

    func cancelTasks() {
        randomJokeTask?.cancel()
        categoriesTask?.cancel()
    }
}

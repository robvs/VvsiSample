//  Copyright © 2024 Rob Vander Sloot
//

import Combine
import Foundation
import OSLog

/// Provides navigation coordinations for the app's root landing screen (e.g. home screen).
class MainCoordinator {

    /// Screens to which this coordinator navigates.
    ///
    /// Note that `ViewInteractor`s are used as the path data in order to keep them
    /// in scope while their associated view is on the nav stack and to cause them to go
    /// out of scope (e.g. deinit) when their associated view is removed from the nav stack.
    enum Link {
        /// Navigation to the Category screen
        case category(pathData: any ViewInteracting<CategoryViewState>)
    }

    /// This is injected as an environment object on the home screen to
    /// manage the navigation stack.
    let navigationState = NavigationState()

    // MARK: Home view dependencies.
    private let homeViewInteractor: HomeViewInteractor
    var homeViewState: HomeViewState { return homeViewInteractor.viewState }

    private var cancellables: [Combine.AnyCancellable] = []

    init() {
        homeViewInteractor = Self.createHomeViewInteractor()

        homeViewInteractor.navigationEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .category(name: let name):
                    let categoryViewState = CategoryViewState(categoryName: name)
                    let categoryViewInteractor = CategoryViewInteractor(viewState: categoryViewState,
                                                                        session: AppUrlSession.shared)

                    Logger.view.debug("Append CategoryViewInteractor to nav path.")
                    self?.navigationState.path.append(Link.category(pathData: categoryViewInteractor))

                case .dismiss:
                    Logger.view.debug("Remove \(type(of: self?.navigationState.path)) from nav path.")
                    self?.navigationState.path.removeLast()
                }
            }
            .store(in: &cancellables)
    }
}


// MARK: - Private Helpers

private extension MainCoordinator {

    static func createHomeViewInteractor() -> HomeViewInteractor {
        return HomeViewInteractor(viewState: HomeViewState(), 
                                  session: AppUrlSession.shared)
    }
}


// MARK: - Link extensions

// Hashable conformance is needed to help with `NavigationPathing`.
extension MainCoordinator.Link: Hashable {

    /// Convenience property that provides the ViewInteractor that is associated with a given Link.
    var pathData: any ViewInteracting<CategoryViewState> {
        switch self {
        case .category(let pathData):
            return pathData
        }
    }

    /// Links are equivalent if their associated `pathData` is the same type.
    static func == (lhs: MainCoordinator.Link, rhs: MainCoordinator.Link) -> Bool {
        return type(of: lhs.pathData) == type(of: rhs.pathData)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine("\(type(of: pathData))")
    }
}

//  Copyright © 2024 Rob Vander Sloot
//

import Combine
import Foundation
import OSLog

/// Provides navigation coordination for the app's root landing screen (e.g. `HomeView`).
class MainCoordinator {

    /// Screens to which this coordinator navigates.
    ///
    /// Note that `pathData` is typically the `ViewInteractor` that is associated with
    /// the target view. This keeps an instance of the interactor in scope while its associated
    /// view is on the nav stack. This also causes the instance to go out of scope when its
    /// associated view is removed from the nav stack, thus freeing the interactor from memory.
    enum Link {
        /// Category screen
        case category(pathData: any NavigationPathable<CategoryViewState>)
    }

    /// This is injected as an environment object on the home screen to
    /// manage the navigation stack.
    let navigationState = NavigationState()

    /// Root view interactor that must stay in scope.
    let homeViewInteractor: HomeViewInteractor

    private var cancellables: [Combine.AnyCancellable] = []

    init() {
        homeViewInteractor = Self.createHomeViewInteractor()
        listenForNavigationEvents(on: homeViewInteractor)
    }
}


// MARK: - Private Helpers

private extension MainCoordinator {

    static func createHomeViewInteractor() -> HomeViewInteractor {
        return HomeViewInteractor(viewState: HomeViewState(), 
                                  session: AppUrlSession.shared)
    }

    func listenForNavigationEvents(on homeViewInteractor: HomeViewInteractor) {
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
                }
            }
            .store(in: &cancellables)
    }
}


// MARK: - Link extensions

// Hashable conformance is needed to help with `NavigationPath` compatibility.
extension MainCoordinator.Link: Hashable {

    /// Convenience property that provides the ViewInteractor that is associated with a given Link.
    var pathData: any NavigationPathable<CategoryViewState> {
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

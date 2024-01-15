//  Copyright © 2024 Rob Vander Sloot
//

import Combine
import Foundation

/// Base interface for `ViewInteractor`s, which handles interactions between views
/// and the rest of the system (i.e. web services, repositories, etc.).
///
/// One of the primary uses of this protocol is to provide the navigation path data (and data type)
/// used by navigation coordinators and `NavigationStack`s.
protocol ViewInteracting<ViewState> {
    associatedtype ViewState

    /// Manages the dynamic elements of a view as well as user interactions.
    var viewState: ViewState { get }
}

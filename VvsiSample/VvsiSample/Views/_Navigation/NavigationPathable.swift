//  Copyright © 2024 Rob Vander Sloot
//

import Combine
import Foundation

/// Interface for objects that are used as `NavigationPath` data, which are typically
/// `ViewInteractor`s.
protocol NavigationPathable<ViewState> {
    associatedtype ViewState

    /// Manages the dynamic elements of a view as well as user interactions.
    var viewState: ViewState { get }
}

//  Copyright © 2024 Rob Vander Sloot
//

import Foundation

/// This is applied to ViewInteractors so that they can be used in the `NavigationPath`
/// in a generic way.
protocol NavigationPathing<ViewState> {
    associatedtype ViewState

    /// The View State that is linked to a particular destination for a `NavigationStack`.
    var viewState: ViewState { get }
}

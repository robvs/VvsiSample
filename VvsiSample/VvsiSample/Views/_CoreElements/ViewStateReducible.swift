//  Copyright © 2024 Rob Vander Sloot
//

import Foundation

/// Protocol that is implemented by all view states.
public protocol ViewStateReducible {

    /// The Action type that is defined by a specific view state.
    associatedtype Action

    /// The Effect type that is defined by a specific view state.
    associatedtype Effect

    /// Handle changes from the current state to the next state.
    /// - Parameter effect: Indicates how the view state should change.
    mutating func reduce(with effect: Effect)
}

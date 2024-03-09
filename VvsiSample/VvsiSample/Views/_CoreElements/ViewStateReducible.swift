//  Copyright © 2024 Rob Vander Sloot
//

import Foundation

/// Protocol that is implemented by all view states.
public protocol ViewStateReducible {
    associatedtype Action
    associatedtype Effect
    mutating func reduce(with effect: Effect)
}

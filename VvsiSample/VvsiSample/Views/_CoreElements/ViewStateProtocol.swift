//  Copyright © 2024 Rob Vander Sloot
//

import Foundation

/// Protocol that is implemented by all view states and is consumed by a view agent.
protocol ViewStateProtocol {
    associatedtype Action
    associatedtype Effect
    mutating func reduce(with effect: Effect)
}

//  Copyright © 2024 Rob Vander Sloot
//

import SwiftUI

/// Provides the navigation path for a `NavigationStack`.
class NavigationState: ObservableObject {

    /// The current state of a `NavigationStack`.
    @Published var path = NavigationPath()
}

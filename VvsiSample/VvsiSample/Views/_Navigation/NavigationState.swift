//  Copyright © 2024 Rob Vander Sloot
//

import SwiftUI

class NavigationState: ObservableObject {
    @Published var path = NavigationPath()
}

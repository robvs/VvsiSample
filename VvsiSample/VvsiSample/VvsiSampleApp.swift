//  Copyright © 2024 Rob Vander Sloot
//

import SwiftUI

@main
struct VvsiSampleApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView(viewState: HomeViewState())
        }
    }
}

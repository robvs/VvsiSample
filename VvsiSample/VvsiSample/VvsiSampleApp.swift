//  Copyright © 2024 Rob Vander Sloot
//

import SwiftUI

@main
struct VvsiSampleApp: App {
    let mainCoordinator = MainCoordinator()

    var body: some Scene {
        WindowGroup {
            HomeView(viewState: mainCoordinator.homeViewState)
                .environmentObject(mainCoordinator.navigationState)
        }
    }
}

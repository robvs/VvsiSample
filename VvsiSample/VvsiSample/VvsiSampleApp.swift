//  Copyright © 2024 Rob Vander Sloot
//

import SwiftUI

@main
struct VvsiSampleApp: App {
    @StateObject var homeViewInteractor = HomeViewInteractor(viewState: HomeViewState(),
                                                             session: AppUrlSession.shared)
    var body: some Scene {
        WindowGroup {
            HomeView(viewState: homeViewInteractor.viewState)
        }
    }
}

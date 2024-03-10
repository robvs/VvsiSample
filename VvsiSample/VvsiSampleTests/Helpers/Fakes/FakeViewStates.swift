//  Copyright © 2024 Rob Vander Sloot
//

@testable import VvsiSample

class FakeHomeViewState: HomeViewState {
    private (set) var capturedEffect: Effect?

    override func reduce(with effect: Effect) {
        capturedEffect = effect
        super.reduce(with: effect)
    }
}

class FakeCategoryViewState: CategoryViewState {
    private (set) var capturedEffect: Effect?

    override func reduce(with effect: Effect) {
        capturedEffect = effect
        super.reduce(with: effect)
    }
}

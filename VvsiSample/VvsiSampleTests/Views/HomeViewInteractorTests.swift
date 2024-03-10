//  Copyright © 2024 Rob Vander Sloot
//

@testable import VvsiSample
import Combine
import XCTest

final class HomeViewInteractorTests: XCTestCase {

    // MARK: generic test data

    private let jokeUrlString = "https://api.chucknorris.io/jokes/uKVtJZN4TMmT55lX3v752A"
    private let randomJoke = "Chuck Norris was once bitten by a rattlesnake, and after three days of suffering... the rattlesnake finally died!"
    private let categories = ["category01", "category02"]
    private var cancellables: [AnyCancellable] = []

    // MARK: Setup/Teardown

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
}


// MARK: - Initialization

extension HomeViewInteractorTests {

    func test_initialState_loadSuccess() async throws {
        // Setup/Execute
        let viewState = FakeHomeViewState()
        let (sut, urlSession) = await createSut(viewState: viewState)

        // Validate the initial view state
        XCTAssertNil(sut.viewState.state.randomJoke)
        XCTAssertNil(sut.viewState.state.categories)

        // wait for the init() actions to complete (i.e. the two `get()`
        // requests on the urlSession)
        _ = await waitFor(urlCount: 2, on: urlSession)

        // Validate the view state after a random joke is received
        urlSession.triggerJokeResponse(with: ChuckNorrisJoke(iconUrl: nil, id: "id01", url: jokeUrlString, value: randomJoke))
        let expectedJokeResult = GetRandomJokeResult.success(randomJoke)
        await expect(effect: .getRandomJokeResult(expectedJokeResult), on: viewState)

        // Validate the view state after categories are received
        urlSession.triggerCategoriesResponse(with: categories)
        let expectedCategoriesResult = GetCategoriesResult.success(categories)
        await expect(effect: .getCategoriesResult(expectedCategoriesResult), on: viewState)
    }

    func test_initialState_loadFailure() async throws {
        // Setup/Execute
        let viewState = FakeHomeViewState()
        let (sut, urlSession) = await createSut(viewState: viewState)

        // Validate the initial view state
        XCTAssertNil(sut.viewState.state.randomJoke)
        XCTAssertNil(sut.viewState.state.categories)

        // wait for the init() actions to complete (i.e. the two `get()`
        // requests on the urlSession)
        _ = await waitFor(urlCount: 2, on: urlSession)

        // Validate the view state after the random joke request fails
        urlSession.triggerJokeResponse(with: nil)
        let expectedJokeResult = GetRandomJokeResult.failure(FakeUrlSession.requestError)
        await expect(effect: .getRandomJokeResult(expectedJokeResult), on: viewState)

        // Validate the view state after the categories request fails are received
        urlSession.triggerCategoriesResponse(with: nil)
        let expectedCategoriesResult = GetCategoriesResult.failure(FakeUrlSession.requestError)
        await expect(effect: .getCategoriesResult(expectedCategoriesResult), on: viewState)
    }
}


// MARK: - Events

extension HomeViewInteractorTests {

    func test_refreshButtonPressed() async throws {
        // Setup
        let viewState = FakeHomeViewState()
        let (sut, urlSession) = await createSut(viewState: viewState, makeReady: true)
        let sessionUrlCount = urlSession.capturedUrls.count

        // Execute
        sut.viewState.send(action: .refreshButtonPressed)

        // wait for the refresh `get()` request to be made on the urlSession
        _ = await waitFor(urlCount: sessionUrlCount + 1, on: urlSession)

        // Validate
        await expect(effect: .loadingRandomJoke, on: viewState)

        urlSession.triggerJokeResponse(with: ChuckNorrisJoke(iconUrl: nil, id: "id01", url: jokeUrlString, value: randomJoke))
        let expectedJokeResult = GetRandomJokeResult.success(randomJoke)
        await expect(effect: .getRandomJokeResult(expectedJokeResult), on: viewState)
    }

    func test_categorySelected() async throws {
        // Setup
        let selectedCategory = categories[0]
        let viewState = FakeHomeViewState()
        let (sut, _) = await createSut(viewState: viewState, makeReady: true)

        // listen for navigation events published by the sut
        let categoryNavigationEventTracker = CapturedObject<String>()
        sut.navigationEventPublisher
            .sink { event in
                switch event {
                case .category(let categoryName):
                    categoryNavigationEventTracker.object = categoryName
                }
            }
            .store(in: &cancellables)

        // Execute
        sut.viewState.send(action: .categorySelected(name: selectedCategory))

        // Validate
        await expect(value: selectedCategory, on: categoryNavigationEventTracker)
    }
}


// MARK: - Private Helpers

private extension HomeViewInteractorTests {

    func createSut(viewState: HomeViewState, makeReady: Bool = false) async -> (HomeViewInteractor, FakeUrlSession) {
        let urlSession = FakeUrlSession()
        let sut = HomeViewInteractor(viewState: viewState, session: urlSession)

        if makeReady {
            // wait for the init() actions to complete (i.e. the two `get()`
            // requests on the urlSession)
            _ = await waitFor(urlCount: 2, on: urlSession)

            // get to the `.ready` state
            urlSession.triggerJokeResponse(with: ChuckNorrisJoke(iconUrl: nil, id: "id01", url: jokeUrlString, value: randomJoke))
            urlSession.triggerCategoriesResponse(with: categories)
            await expectReady(on: sut)
        }

        return (sut, urlSession)
    }

    /// Wait for the specified effect on the given view state.
    /// - parameters:
    ///  - effect: The effect that is expected to be applied to the given view state.
    ///  - viewState: The view state to which the effect is expected to be applied.
    func expect(effect: HomeViewState.Effect, on viewState: FakeHomeViewState) async {
        let predicate = NSPredicate { (evalObject, _) -> Bool in
            return (evalObject as! FakeHomeViewState).capturedEffect == effect
        }

        if await wait(forPredicate: predicate, evaluateWith: viewState, timeout: 0.5) == false {
            XCTFail("The expected effect \(effect) was not set in the allotted time. Actual effect: \(String(describing: viewState.capturedEffect))")
        }
    }

    /// Wait for the random joke and categories to be loaded on the given view interactor.
    /// - parameters:
    ///  - viewInteractor: The view interactor on which async tasks are in process.
    func expectReady(on viewInteractor: HomeViewInteractor) async {
        let predicate = NSPredicate { (evalObject, _) -> Bool in
            let viewState = (evalObject as! HomeViewInteractor).viewState
            return viewState.state.randomJoke != nil &&
                   viewState.state.categories != nil
        }

        if await wait(forPredicate: predicate, evaluateWith: viewInteractor, timeout: 0.5) == false {
            XCTFail("View interactor is not ready in the allotted time.")
        }
    }

    func waitFor(urlCount: Int, on urlSession: FakeUrlSession) async -> Bool {
        let predicate = NSPredicate { (evalObject, _) -> Bool in
            return (evalObject as! FakeUrlSession).capturedUrls.count == urlCount
        }

        return await wait(forPredicate: predicate, evaluateWith: urlSession, timeout: 0.5)
    }
}

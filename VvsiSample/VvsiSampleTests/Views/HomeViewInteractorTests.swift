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

    // Combine subjects that are used to trigger a response in FakeUrlSession.get()
    private let jokeSubject = PassthroughSubject<ChuckNorrisJoke?, Never>()
    private let categoriesSubject = PassthroughSubject<[String]?, Never>()

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
        let (sut, urlSession) = await createSut()

        // Validate the initial view state
        XCTAssertEqual(sut.viewState.currentState, .loading(includesRandomJoke: true, includesCategories: true))

        // wait for the init() actions to complete (i.e. the two `get()`
        // requests on the urlSession)
        _ = await waitFor(urlCount: 2, on: urlSession)

        // Validate the view state after a random joke is received
        jokeSubject.send(ChuckNorrisJoke(iconUrl: nil, id: "id01", url: jokeUrlString, value: randomJoke))
        await expect(state: .loading(includesRandomJoke: false, includesCategories: true), on: sut)
        XCTAssertEqual(sut.viewState.randomJoke, randomJoke)

        // Validate the view state after categories are received
        categoriesSubject.send(categories)
        await expect(state: .ready, on: sut)
        XCTAssertEqual(sut.viewState.categories, categories)
    }

    func test_initialState_loadFailure() async throws {
        // Setup/Execute
        let (sut, urlSession) = await createSut()

        // Validate the initial view state
        XCTAssertEqual(sut.viewState.currentState, .loading(includesRandomJoke: true, includesCategories: true))

        // wait for the init() actions to complete (i.e. the two `get()`
        // requests on the urlSession)
        _ = await waitFor(urlCount: 2, on: urlSession)

        // Validate the view state after the random joke request fails
        jokeSubject.send(nil)
        await expect(state: .loading(includesRandomJoke: false, includesCategories: true), on: sut)
        XCTAssertNil(sut.viewState.randomJoke)

        // Validate the view state after the categories request fails are received
        categoriesSubject.send(nil)
        await expect(state: .ready, on: sut)
        XCTAssertNil(sut.viewState.categories)
    }
}


// MARK: - Events

extension HomeViewInteractorTests {

    func test_refreshButtonPressed() async throws {
        // Setup
        let expectedJoke = "This is a different joke."
        let (sut, urlSession) = await createSut(makeReady: true)
        let sessionUrlCount = urlSession.capturedUrls.count

        // Execute
        sut.viewState.on(event: .refreshButtonPressed)

        // wait for the refresh `get()` request to be made on the urlSession
        _ = await waitFor(urlCount: sessionUrlCount + 1, on: urlSession)

        // Validate
        await expect(state: .loading(includesRandomJoke: true, includesCategories: false), on: sut)

        jokeSubject.send(ChuckNorrisJoke(iconUrl: nil, id: "id01", url: jokeUrlString, value: expectedJoke))
        await expect(state: .ready, on: sut)
        XCTAssertEqual(sut.viewState.randomJoke, expectedJoke)
    }

    func test_categorySelected() async throws {
        // Setup
        let selectedCategory = categories[0]
        let (sut, urlSession) = await createSut(makeReady: true)

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
        sut.viewState.on(event: .categorySelected(name: selectedCategory))

        // Validate
        await expect(value: selectedCategory, on: categoryNavigationEventTracker)
    }
}


// MARK: - Private Helpers

private extension HomeViewInteractorTests {

    func createSut(makeReady: Bool = false) async -> (HomeViewInteractor, FakeUrlSession) {
        let viewState = HomeViewState()
        let urlSession = FakeUrlSession(jokePublisher: jokeSubject.eraseToAnyPublisher(),
                                        categoriesPublisher: categoriesSubject.eraseToAnyPublisher())
        let sut = HomeViewInteractor(viewState: viewState, session: urlSession)

        if makeReady {
            // wait for the init() actions to complete (i.e. the two `get()`
            // requests on the urlSession)
            _ = await waitFor(urlCount: 2, on: urlSession)

            // get to the `.ready` state
            jokeSubject.send(ChuckNorrisJoke(iconUrl: nil, id: "id01", url: jokeUrlString, value: randomJoke))
            categoriesSubject.send(categories)
            await expect(state: .ready, on: sut)
        }

        return (sut, urlSession)
    }

    /// Wait for the specified state on the given view interactor.
    /// - parameters:
    ///  - state: The state that is expected on the given view interactor once async tasks complete.
    ///  - viewInteractor: The view interactor on which async tasks are in process.
    func expect(state: HomeViewState.State, on viewInteractor: HomeViewInteractor) async {
        let predicate = NSPredicate { (evalObject, _) -> Bool in
            return (evalObject as! HomeViewInteractor).viewState.currentState == state
        }

        if await wait(forPredicate: predicate, evaluateWith: viewInteractor, timeout: 0.5) == false {
            XCTFail("State \(state) was not set in the allotted time. Actual state: \(viewInteractor.viewState.currentState)")
        }
    }

    func waitFor(urlCount: Int, on urlSession: FakeUrlSession) async -> Bool {
        let predicate = NSPredicate { (evalObject, _) -> Bool in
            return (evalObject as! FakeUrlSession).capturedUrls.count == urlCount
        }

        return await wait(forPredicate: predicate, evaluateWith: urlSession, timeout: 0.5)
    }
}

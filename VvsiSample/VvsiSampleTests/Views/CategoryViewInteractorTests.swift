//  Copyright © 2024 Rob Vander Sloot
//

@testable import VvsiSample
import Combine
import XCTest

final class CategoryViewInteractorTests: XCTestCase {

    // MARK: generic test data

    private let genericCategory = "Category1"
    private let jokes = ["Joke 1", "Joke 2", "Joke 3", "Joke 4", "Joke 5"]
    private let jokeUrlString = "https://api.chucknorris.io/jokes/uKVtJZN4TMmT55lX3v752A"

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

extension CategoryViewInteractorTests {

    func test_initialState_loadSuccess() async throws {
        // Setup/Execute
        let (sut, urlSession) = await createSut()

        // Validate the initial view state
        XCTAssertEqual(sut.viewState.currentState, .loading)

        // wait for the interactor to make the full set of joke requests
        // on the session with the specified set of responses.
        await trigger(jokeResponses: jokes, on: urlSession)

        // Validate initial view state after loading has completed
        await expect(state: .ready(categoryJokes: jokes), on: sut)
    }

    func test_initialState_loadFailure() async throws {
        // Setup/Execute
        let (sut, urlSession) = await createSut()

        // Validate the initial view state
        XCTAssertEqual(sut.viewState.currentState, .loading)

        // cause the first joke request to fail
        _ = await waitFor(urlCount: 1, on: urlSession)
        urlSession.triggerJokeResponse(with: nil)

        // Validate initial view state after loading has completed
        await expect(state: .error(message: FakeUrlSession.requestError.localizedDescription), on: sut)
    }

    func test_initialState_duplicateJokes() async throws {
        // Setup/Execute
        let duplicates = ["Joke 1", "Joke 1", "Joke 2", "Joke 2", "Joke 2"]
        let (sut, urlSession) = await createSut()

        // Validate the initial view state
        XCTAssertEqual(sut.viewState.currentState, .loading)

        // wait for the interactor to make the full set of joke requests
        // on the session with the specified set of responses.
        await trigger(jokeResponses: duplicates, on: urlSession)

        // Validate initial view state after loading has completed
        await expect(state: .ready(categoryJokes: ["Joke 1", "Joke 2"]), on: sut)
    }
}


// MARK: - Events

extension CategoryViewInteractorTests {

    func test_refreshButtonPressed_success() async throws {
        // Setup
        let (sut, urlSession) = await createSut(makeReady: true)
        let originalRequestCount = urlSession.capturedUrls.count

        // Execute
        sut.viewState.on(event: .refreshButtonPressed)

        // wait for the interactor to make the full set of joke requests
        // on the session with the specified set of responses.
        let otherJokes = ["other joke 1", "other joke 2", "other joke 3", "other joke 4", "other joke 5"]
        await trigger(jokeResponses: otherJokes,
                      on: urlSession,
                      previousRequestCount: originalRequestCount)

        // Validate
        await expect(state: .ready(categoryJokes: otherJokes), on: sut)
    }

    func test_refreshButtonPressed_failure() async throws {
        // Setup
        let (sut, urlSession) = await createSut(makeReady: true)
        let originalRequestCount = urlSession.capturedUrls.count

        // Execute
        sut.viewState.on(event: .refreshButtonPressed)

        // cause the first joke request to fail
        _ = await waitFor(urlCount: originalRequestCount + 1, on: urlSession)
        urlSession.triggerJokeResponse(with: nil)

        // Validate
        await expect(state: .error(message: FakeUrlSession.requestError.localizedDescription), on: sut)
    }
}


// MARK: - Private Helpers

private extension CategoryViewInteractorTests {

    func createSut(makeReady: Bool = false) async -> (CategoryViewInteractor, FakeUrlSession) {
        let viewState = CategoryViewState(categoryName: genericCategory)
        let urlSession = FakeUrlSession()
        let sut = CategoryViewInteractor(viewState: viewState, session: urlSession)

        if makeReady {
            await trigger(jokeResponses: jokes, on: urlSession)
        }

        return (sut, urlSession)
    }

    /// Wait for the specified state on the given view interactor.
    /// - parameters:
    ///  - state: The state that is expected on the given view interactor once async tasks complete.
    ///  - viewInteractor: The view interactor on which async tasks are in process.
    func expect(state: CategoryViewState.State, on viewInteractor: CategoryViewInteractor) async {
        let predicate = NSPredicate { (evalObject, _) -> Bool in
            return (evalObject as! CategoryViewInteractor).viewState.currentState == state
        }

        if await wait(forPredicate: predicate, evaluateWith: viewInteractor, timeout: 0.5) == false {
            XCTFail("State \(state) was not set in the allotted time. Actual state: \(viewInteractor.viewState.currentState)")
        }
    }

    /// The interactor makes `CategoryViewInteractor.jokeCount` number of random joke
    /// requests when loading and refreshing. This method waits for all of those requests to complete.
    /// - parameters:
    ///  - urlSession: The session on which the requests are made by the interactor and
    ///                are fulfilled here.
    ///  - previousRequestCount: The total number of requests that have previously been
    ///                          made on the session.
    func trigger(jokeResponses: [String],
                 on urlSession: FakeUrlSession,
                 previousRequestCount: Int = 0) async {
        // this is a little tricky because when the interactor makes a set
        // of joke requests, each request is only made after the previous
        // request returns. this means that the following gymnastics are
        // required to get through all of the requests.
        //
        // note: this would be a little less complicated if the interactor
        // made the requests in parallel (it would also be more efficient for
        // the app), but that can be left as an exercise for the reader ;)
        for index in 0..<CategoryViewInteractor.jokeCount {
            // wait for the next joke request to be made
            if await waitFor(urlCount: previousRequestCount + index + 1,
                             on: urlSession) == false {
                XCTFail("The interactor did not make the expected number of requests.")
            }

            // trigger the response to that request
            urlSession.triggerJokeResponse(
                with: ChuckNorrisJoke(iconUrl: nil,
                                      id: "id01",
                                      url: jokeUrlString,
                                      value: jokeResponses[index]))
        }
    }

    func waitFor(urlCount: Int, on urlSession: FakeUrlSession) async -> Bool {
        let predicate = NSPredicate { (evalObject, _) -> Bool in
            return (evalObject as! FakeUrlSession).capturedUrls.count == urlCount
        }

        return await wait(forPredicate: predicate, evaluateWith: urlSession, timeout: 0.5)
    }
}

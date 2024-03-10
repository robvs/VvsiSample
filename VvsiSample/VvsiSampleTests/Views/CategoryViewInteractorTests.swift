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
        let viewState = FakeCategoryViewState(categoryName: genericCategory)
        let (sut, urlSession) = await createSut(viewState: viewState)

        // Validate the initial view state
        XCTAssertEqual(sut.viewState.state.isLoading, true)

        // wait for the interactor to make the full set of joke requests
        // on the session with the specified set of responses.
        await trigger(jokeResponses: jokes, on: urlSession)

        // Validate that the expected effect was applied to the view state.
        let requestResult = GetRandomJokesResult.success(jokes)
        await expect(effect: .getRandomJokesResult(requestResult), on: viewState)
    }

    func test_initialState_loadFailure() async throws {
        // Setup/Execute
        let viewState = FakeCategoryViewState(categoryName: genericCategory)
        let (sut, urlSession) = await createSut(viewState: viewState)

        // Validate the initial view state
        XCTAssertEqual(sut.viewState.state.isLoading, true)

        // cause the first joke request to fail
        _ = await waitFor(urlCount: 1, on: urlSession)
        urlSession.triggerJokeResponse(with: nil)

        // Validate that the expected effect was applied to the view state.
        let requestResult = GetRandomJokesResult.failure(FakeUrlSession.requestError)
        await expect(effect: .getRandomJokesResult(requestResult), on: viewState)
    }

    func test_initialState_duplicateJokes() async throws {
        // Setup/Execute
        let duplicates = ["Joke 1", "Joke 1", "Joke 2", "Joke 2", "Joke 2"]
        let viewState = FakeCategoryViewState(categoryName: genericCategory)
        let (sut, urlSession) = await createSut(viewState: viewState)

        // Validate the initial view state
        XCTAssertEqual(sut.viewState.state.isLoading, true)

        // wait for the interactor to make the full set of joke requests
        // on the session with the specified set of responses.
        await trigger(jokeResponses: duplicates, on: urlSession)

        // Validate that the expected effect was applied to the view state.
        let requestResult = GetRandomJokesResult.success(["Joke 1", "Joke 2"])
        await expect(effect: .getRandomJokesResult(requestResult), on: viewState)
    }
}


// MARK: - Events

extension CategoryViewInteractorTests {

    func test_refreshButtonPressed_success() async throws {
        // Setup
        let viewState = FakeCategoryViewState(categoryName: genericCategory)
        let (sut, urlSession) = await createSut(viewState: viewState, makeReady: true)
        let originalRequestCount = urlSession.capturedUrls.count

        // Execute
        sut.viewState.send(action: .refreshButtonPressed)

        // wait for the interactor to make the full set of joke requests
        // on the session with the specified set of responses.
        let otherJokes = ["other joke 1", "other joke 2", "other joke 3", "other joke 4", "other joke 5"]
        await trigger(jokeResponses: otherJokes,
                      on: urlSession,
                      previousRequestCount: originalRequestCount)

        // Validate
        let requestResult = GetRandomJokesResult.success(otherJokes)
        await expect(effect: .getRandomJokesResult(requestResult), on: viewState)
    }

    func test_refreshButtonPressed_failure() async throws {
        // Setup
        let viewState = FakeCategoryViewState(categoryName: genericCategory)
        let (sut, urlSession) = await createSut(viewState: viewState, makeReady: true)
        let originalRequestCount = urlSession.capturedUrls.count

        // Execute
        sut.viewState.send(action: .refreshButtonPressed)

        // cause the first joke request to fail
        _ = await waitFor(urlCount: originalRequestCount + 1, on: urlSession)
        urlSession.triggerJokeResponse(with: nil)

        // Validate
        let requestResult = GetRandomJokesResult.failure(FakeUrlSession.requestError)
        await expect(effect: .getRandomJokesResult(requestResult), on: viewState)
    }
}


// MARK: - Private Helpers

private extension CategoryViewInteractorTests {

    func createSut(viewState: CategoryViewState, makeReady: Bool = false) async -> (CategoryViewInteractor, FakeUrlSession) {
        let urlSession = FakeUrlSession()
        let sut = CategoryViewInteractor(viewState: viewState, session: urlSession)

        if makeReady {
            await trigger(jokeResponses: jokes, on: urlSession)
        }

        return (sut, urlSession)
    }

    /// Wait for the specified effect on the given view state.
    /// - parameters:
    ///  - effect: The effect that is expected to be applied to the given view state.
    ///  - viewState: The view state to which the effect is expected to be applied.
    func expect(effect: CategoryViewState.Effect, on viewState: FakeCategoryViewState) async {
        let predicate = NSPredicate { (evalObject, _) -> Bool in
            return (evalObject as! FakeCategoryViewState).capturedEffect == effect
        }

        if await wait(forPredicate: predicate, evaluateWith: viewState, timeout: 0.5) == false {
            XCTFail("The expected effect \(effect) was not set in the allotted time. Actual effect: \(String(describing: viewState.capturedEffect))")
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

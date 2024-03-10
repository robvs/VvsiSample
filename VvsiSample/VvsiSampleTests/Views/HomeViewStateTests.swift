//  Copyright © 2024 Rob Vander Sloot
//

@testable import VvsiSample
import XCTest

final class HomeViewStateTests: XCTestCase {

    private let someJoke = "This is a joke."
    private let someCategories = ["Category1", "Category2", "Category3", "Category4"]
    private let someError = AppUrlSession.RequestError.serverResponse(code: 404)

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
}


// MARK: - Initial State

extension HomeViewStateTests {

    func test_initialState() throws {
        // Setup/Execute
        let sut = HomeViewState()

        // Validate
        XCTAssertNil(sut.state.randomJoke)
        XCTAssertNil(sut.state.randomJokeError)
        XCTAssertNil(sut.state.categories)
        XCTAssertNil(sut.state.categoriesError)
        XCTAssertEqual(sut.state.refreshButtonDisabled, true)
    }
}


// MARK: - update(randomJoke:, errorMessage:)

extension HomeViewStateTests {

    func test_randomJokeSuccess_categoriesLoading() async throws {
        // Setup
        let result = GetRandomJokeResult.success(someJoke)
        let sut = HomeViewState()

        // Execute
        sut.reduce(with: .getRandomJokeResult(result))

        // Validate
        XCTAssertEqual(sut.state.randomJoke, someJoke)
        XCTAssertNil(sut.state.randomJokeError)
        XCTAssertNil(sut.state.categories)
        XCTAssertNil(sut.state.categoriesError)
        XCTAssertEqual(sut.state.refreshButtonDisabled, false)
    }

    func test_randomJokeSuccess_categoriesLoaded() async throws {
        // Setup
        let jokeResult = GetRandomJokeResult.success(someJoke)
        let categoriesResult = GetCategoriesResult.success(someCategories)
        let sut = HomeViewState()
        sut.reduce(with: .getCategoriesResult(categoriesResult))

        // Execute
        sut.reduce(with: .getRandomJokeResult(jokeResult))

        // Validate
        XCTAssertEqual(sut.state.randomJoke, someJoke)
        XCTAssertNil(sut.state.randomJokeError)
        XCTAssertEqual(sut.state.categories?.count, someCategories.count)
        XCTAssertNil(sut.state.categoriesError)
        XCTAssertEqual(sut.state.refreshButtonDisabled, false)
    }

    func test_randomJokeFail() async throws {
        // Setup
        let jokeResult = GetRandomJokeResult.failure(someError)
        let sut = HomeViewState()

        // Execute
        sut.reduce(with: .getRandomJokeResult(jokeResult))

        // Validate
        XCTAssertEqual(sut.state.randomJoke?.isEmpty, true)
        XCTAssertEqual(sut.state.randomJokeError, someError.localizedDescription)
        XCTAssertNil(sut.state.categories)
        XCTAssertNil(sut.state.categoriesError)
        XCTAssertEqual(sut.state.refreshButtonDisabled, false)
    }

    func test_randomJokeFail_categoriesLoaded() async throws {
        // Setup
        let jokeResult = GetRandomJokeResult.failure(someError)
        let categoriesResult = GetCategoriesResult.success(someCategories)
        let sut = HomeViewState()
        sut.reduce(with: .getCategoriesResult(categoriesResult))

        // Execute
        sut.reduce(with: .getRandomJokeResult(jokeResult))

        // Validate
        XCTAssertEqual(sut.state.randomJoke?.isEmpty, true)
        XCTAssertEqual(sut.state.randomJokeError, someError.localizedDescription)
        XCTAssertEqual(sut.state.categories?.count, someCategories.count)
        XCTAssertNil(sut.state.categoriesError)
        XCTAssertEqual(sut.state.refreshButtonDisabled, false)
    }
}


// MARK: - update(categories:, errorMessage:)

extension HomeViewStateTests {

    func test_categoriesSuccess_randomJokeLoading() async throws {
        // Setup
        let result = GetCategoriesResult.success(someCategories)
        let sut = HomeViewState()

        // Execute
        sut.reduce(with: .getCategoriesResult(result))

        // Validate
        XCTAssertNil(sut.state.randomJoke)
        XCTAssertNil(sut.state.randomJokeError)
        XCTAssertEqual(sut.state.categories?.count, someCategories.count)
        XCTAssertNil(sut.state.categoriesError)
        XCTAssertEqual(sut.state.refreshButtonDisabled, true)
    }

    func test_categoriesSuccess_randomJokeLoaded() async throws {
        // Setup
        let jokeResult = GetRandomJokeResult.success(someJoke)
        let categoriesResult = GetCategoriesResult.success(someCategories)
        let sut = HomeViewState()
        sut.reduce(with: .getRandomJokeResult(jokeResult))

        // Execute
        sut.reduce(with: .getCategoriesResult(categoriesResult))

        // Validate
        XCTAssertEqual(sut.state.randomJoke, someJoke)
        XCTAssertNil(sut.state.randomJokeError)
        XCTAssertEqual(sut.state.categories?.count, someCategories.count)
        XCTAssertNil(sut.state.categoriesError)
        XCTAssertEqual(sut.state.refreshButtonDisabled, false)
    }

    func test_categoriesFail() async throws {
        // Setup
        let categoriesResult = GetCategoriesResult.failure(someError)
        let sut = HomeViewState()

        // Execute
        sut.reduce(with: .getCategoriesResult(categoriesResult))

        // Validate
        XCTAssertNil(sut.state.randomJoke)
        XCTAssertNil(sut.state.randomJokeError)
        XCTAssertEqual(sut.state.categories?.isEmpty, true)
        XCTAssertEqual(sut.state.categoriesError, someError.localizedDescription)
        XCTAssertEqual(sut.state.refreshButtonDisabled, true)
    }

    func test_categoriesFail_randomJokeLoaded() async throws {
        // Setup
        let jokeResult = GetRandomJokeResult.success(someJoke)
        let categoriesResult = GetCategoriesResult.failure(someError)
        let sut = HomeViewState()
        sut.reduce(with: .getRandomJokeResult(jokeResult))

        // Execute
        sut.reduce(with: .getCategoriesResult(categoriesResult))

        // Validate
        XCTAssertEqual(sut.state.randomJoke, someJoke)
        XCTAssertNil(sut.state.randomJokeError)
        XCTAssertEqual(sut.state.categories?.isEmpty, true)
        XCTAssertEqual(sut.state.categoriesError, someError.localizedDescription)
        XCTAssertEqual(sut.state.refreshButtonDisabled, false)
    }
}

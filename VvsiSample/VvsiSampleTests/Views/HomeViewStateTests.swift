//  Copyright © 2024 Rob Vander Sloot
//

@testable import VvsiSample
import XCTest

final class HomeViewStateTests: XCTestCase {

    let someJoke = "This is a joke."
    let someCategories = ["Category1", "Category2", "Category3", "Category4"]
    let someErrorMessage = "An error happened. No joke."

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
        XCTAssertEqual(sut.currentState, .loading(includesRandomJoke: true, includesCategories: true))
        XCTAssertNil(sut.randomJoke)
        XCTAssertNil(sut.randomJokeError)
        XCTAssertNil(sut.categories)
        XCTAssertNil(sut.categoriesError)
        XCTAssertEqual(sut.refreshButtonDisabled, true)
    }
}


// MARK: - update(randomJoke:, errorMessage:)

extension HomeViewStateTests {

    func test_updateRandomJoke_categoriesLoading() async throws {
        // Setup
        let sut = HomeViewState()

        // Execute
        await sut.update(randomJoke: someJoke)

        // Validate
        XCTAssertEqual(sut.currentState, .loading(includesRandomJoke: false, includesCategories: true))
        XCTAssertEqual(sut.randomJoke, someJoke)
        XCTAssertNil(sut.randomJokeError)
        XCTAssertNil(sut.categories)
        XCTAssertNil(sut.categoriesError)
        XCTAssertEqual(sut.refreshButtonDisabled, true)
    }

    func test_updateRandomJoke_categoriesLoaded() async throws {
        // Setup
        let sut = HomeViewState()
        await sut.update(categories: someCategories)

        // Execute
        await sut.update(randomJoke: someJoke)

        // Validate
        XCTAssertEqual(sut.currentState, .ready)
        XCTAssertEqual(sut.randomJoke, someJoke)
        XCTAssertNil(sut.randomJokeError)
        XCTAssertEqual(sut.categories?.count, someCategories.count)
        XCTAssertNil(sut.categoriesError)
        XCTAssertEqual(sut.refreshButtonDisabled, false)
    }

    func test_updateRandomJoke_withErrorMessage() async throws {
        // Setup
        let sut = HomeViewState()

        // Execute
        await sut.update(randomJoke: nil, errorMessage: someErrorMessage)

        // Validate
        XCTAssertEqual(sut.currentState, .loading(includesRandomJoke: false, includesCategories: true))
        XCTAssertNil(sut.randomJoke)
        XCTAssertEqual(sut.randomJokeError, someErrorMessage)
        XCTAssertNil(sut.categories)
        XCTAssertNil(sut.categoriesError)
        XCTAssertEqual(sut.refreshButtonDisabled, true)
    }

    func test_updateRandomJoke_withErrorMessage_categoriesLoaded() async throws {
        // Setup
        let sut = HomeViewState()
        await sut.update(categories: someCategories)

        // Execute
        await sut.update(randomJoke: nil, errorMessage: someErrorMessage)

        // Validate
        XCTAssertEqual(sut.currentState, .ready)
        XCTAssertNil(sut.randomJoke)
        XCTAssertEqual(sut.randomJokeError, someErrorMessage)
        XCTAssertEqual(sut.categories?.count, someCategories.count)
        XCTAssertNil(sut.categoriesError)
        XCTAssertEqual(sut.refreshButtonDisabled, false)
    }
}


// MARK: - update(categories:, errorMessage:)

extension HomeViewStateTests {

    func test_updateCategories_randomJokeLoading() async throws {
        // Setup
        let sut = HomeViewState()

        // Execute
        await sut.update(categories: someCategories)

        // Validate
        XCTAssertEqual(sut.currentState, .loading(includesRandomJoke: true, includesCategories: false))
        XCTAssertNil(sut.randomJoke)
        XCTAssertNil(sut.randomJokeError)
        XCTAssertEqual(sut.categories?.count, someCategories.count)
        XCTAssertNil(sut.categoriesError)
        XCTAssertEqual(sut.refreshButtonDisabled, true)
    }

    func test_updateCategories_randomJokeLoaded() async throws {
        // Setup
        let sut = HomeViewState()
        await sut.update(randomJoke: someJoke)

        // Execute
        await sut.update(categories: someCategories)

        // Validate
        XCTAssertEqual(sut.currentState, .ready)
        XCTAssertEqual(sut.randomJoke, someJoke)
        XCTAssertNil(sut.randomJokeError)
        XCTAssertEqual(sut.categories?.count, someCategories.count)
        XCTAssertNil(sut.categoriesError)
        XCTAssertEqual(sut.refreshButtonDisabled, false)
    }

    func test_updateCategories_withErrorMessage() async throws {
        // Setup
        let sut = HomeViewState()

        // Execute
        await sut.update(categories: nil, errorMessage: someErrorMessage)

        // Validate
        XCTAssertEqual(sut.currentState, .loading(includesRandomJoke: true, includesCategories: false))
        XCTAssertNil(sut.randomJoke)
        XCTAssertNil(sut.randomJokeError)
        XCTAssertNil(sut.categories)
        XCTAssertEqual(sut.categoriesError, someErrorMessage)
        XCTAssertEqual(sut.refreshButtonDisabled, true)
    }

    func test_updateCategories_withErrorMessage_randomJokeLoaded() async throws {
        // Setup
        let sut = HomeViewState()
        await sut.update(randomJoke: someJoke)

        // Execute
        await sut.update(categories: nil, errorMessage: someErrorMessage)

        // Validate
        XCTAssertEqual(sut.currentState, .ready)
        XCTAssertEqual(sut.randomJoke, someJoke)
        XCTAssertNil(sut.randomJokeError)
        XCTAssertNil(sut.categories)
        XCTAssertEqual(sut.categoriesError, someErrorMessage)
        XCTAssertEqual(sut.refreshButtonDisabled, false)
    }
}

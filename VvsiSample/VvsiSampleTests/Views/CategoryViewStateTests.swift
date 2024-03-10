//  Copyright © 2024 Rob Vander Sloot
//

@testable import VvsiSample
import XCTest

final class CategoryViewStateTests: XCTestCase {

    private let genericCategory = "Category1"
    private let someJokes = ["joke1", "joke2", "joke3", "joke4"]
    private let someError = AppUrlSession.RequestError.serverResponse(code: 404)

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
}


// MARK: - Initial State

extension CategoryViewStateTests {

    func test_initialState() throws {
        // Setup/Execute
        let sut = CategoryViewState(categoryName: genericCategory)

        // Validate
        XCTAssertEqual(sut.state.categoryName, genericCategory)
        XCTAssertEqual(sut.state.isLoading, true)
        XCTAssertEqual(sut.state.jokes.isEmpty, true)
        XCTAssertNil(sut.state.errorMessage)
        XCTAssertEqual(sut.state.refreshButtonDisabled, true)
    }
}


// MARK: - reduce()

extension CategoryViewStateTests {

    func test_reduce_getJokesSuccess() throws {
        // Setup
        let result = GetRandomJokesResult.success(someJokes)
        let sut = CategoryViewState(categoryName: genericCategory)

        // Execute
        sut.reduce(with: .getRandomJokesResult(result))

        // Validate
        XCTAssertEqual(sut.state.categoryName, genericCategory)
        XCTAssertEqual(sut.state.isLoading, false)
        XCTAssertEqual(sut.state.jokes, someJokes)
        XCTAssertNil(sut.state.errorMessage)
        XCTAssertEqual(sut.state.refreshButtonDisabled, false)
    }

    func test_reduce_getJokesError() throws {
        // Setup
        let result = GetRandomJokesResult.failure(someError)
        let sut = CategoryViewState(categoryName: genericCategory)

        // Execute
        sut.reduce(with: .getRandomJokesResult(result))

        // Validate
        XCTAssertEqual(sut.state.categoryName, genericCategory)
        XCTAssertEqual(sut.state.isLoading, false)
        XCTAssertEqual(sut.state.jokes.isEmpty, true)
        XCTAssertEqual(sut.state.errorMessage, someError.localizedDescription)
        XCTAssertEqual(sut.state.refreshButtonDisabled, false)
    }

    func test_reduce_getJokes_then_reload() throws {
        // Setup
        let result = GetRandomJokesResult.success(someJokes)
        let sut = CategoryViewState(categoryName: genericCategory)

        // Execute
        sut.reduce(with: .getRandomJokesResult(result))
        sut.reduce(with: .loading)

        // Validate
        XCTAssertEqual(sut.state.categoryName, genericCategory)
        XCTAssertEqual(sut.state.isLoading, true)
        XCTAssertEqual(sut.state.jokes.isEmpty, true)
        XCTAssertNil(sut.state.errorMessage)
        XCTAssertEqual(sut.state.refreshButtonDisabled, true)
    }
}

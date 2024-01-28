//  Copyright © 2024 Rob Vander Sloot
//

@testable import VvsiSample
import XCTest

final class CategoryViewStateTests: XCTestCase {

    private let genericCategory = "Category1"
    private let someCategories = ["Category1", "Category2", "Category3", "Category4"]
    private let someErrorMessage = "An error happened. No joke."

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
        XCTAssertEqual(sut.categoryName, genericCategory)
        XCTAssertEqual(sut.currentState, .loading)
        XCTAssertEqual(sut.isLoading, true)
        XCTAssertEqual(sut.categoryJokes.count, 0)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.refreshButtonDisabled, true)
    }
}


// MARK: - set(state:)

extension CategoryViewStateTests {

    func test_setState_ready() async throws {
        // Setup
        let expectedState: CategoryViewState.State = .ready(categoryJokes: someCategories)
        let sut = CategoryViewState(categoryName: genericCategory)

        // Execute
        await sut.set(state: expectedState)

        // Validate
        XCTAssertEqual(sut.currentState, expectedState)
        XCTAssertEqual(sut.isLoading, false)
        XCTAssertEqual(sut.categoryJokes.count, someCategories.count)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.refreshButtonDisabled, false)
    }

    func test_setState_error() async throws {
        // Setup
        let expectedState: CategoryViewState.State = .error(message: someErrorMessage)
        let sut = CategoryViewState(categoryName: genericCategory)

        // Execute
        await sut.set(state: expectedState)

        // Validate
        XCTAssertEqual(sut.currentState, expectedState)
        XCTAssertEqual(sut.isLoading, false)
        XCTAssertEqual(sut.categoryJokes.count, 0)
        XCTAssertEqual(sut.errorMessage, someErrorMessage)
        XCTAssertEqual(sut.refreshButtonDisabled, false)
    }

    func test_setState_readyToLoading() async throws {
        // Setup
        let expectedState: CategoryViewState.State = .loading
        let sut = CategoryViewState(categoryName: genericCategory)

        // Execute
        await sut.set(state: .ready(categoryJokes: someCategories))
        await sut.set(state: expectedState)

        // Validate
        XCTAssertEqual(sut.currentState, expectedState)
        XCTAssertEqual(sut.isLoading, true)
        XCTAssertEqual(sut.categoryJokes.count, 0)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.refreshButtonDisabled, true)
    }
}

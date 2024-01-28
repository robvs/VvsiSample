//  Copyright © 2024 Rob Vander Sloot
//

@testable import VvsiSample
import Combine
import Foundation
import OSLog

class FakeUrlSession: AppUrlSessionHandling {

    /// The error that is thrown by `get(from url:)` when a failure response is triggered
    static let requestError = AppUrlSession.RequestError.serverResponse(code: 404)

    /// Keeps track of the URLs that are passed into `get(from url:)`
    private (set) var capturedUrls: [URL] = []

    private var jokeSubjects: [PassthroughSubject<ChuckNorrisJoke?, Never>] = []
    private var categoriesSubjects: [PassthroughSubject<[String]?, Never>] = []
    private var cancellables: [Combine.AnyCancellable] = []
}


// MARK: AppUrlSessionHandling conformance

extension FakeUrlSession {

    func get<Model>(from url: URL) async throws -> Model where Model : Decodable {
        return try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<Model, Error>) in
            guard let self = self else {
                Logger.api.warning("FakeUrlSession went out of scope")
                return
            }

            // setup a publisher on the subject that's associated with `Model` and
            // resume the continuation when a value is received on that publisher.
            switch continuation {
            case let jokeContinuation as CheckedContinuation<ChuckNorrisJoke, Error>:
                let subject = PassthroughSubject<ChuckNorrisJoke?, Never>()
                jokeSubjects.append(subject)
                resume(continuation: jokeContinuation, on: subject.eraseToAnyPublisher())

            case let categoriesContinuation as CheckedContinuation<[String], Error>:
                let subject = PassthroughSubject<[String]?, Never>()
                categoriesSubjects.append(subject)
                resume(continuation: categoriesContinuation, on: subject.eraseToAnyPublisher())

            default:
                Logger.api.error("Unexpected URL session request model type: \(Model.self)")
                continuation.resume(throwing: AppUrlSession.RequestError.unexpected("Unexpected url: \(url.absoluteString)"))
            }

            // NOTE: `capturedUrls` must be set AFTER the `publisher.sink()` because
            //       it is used in tests to indicate that the `get()` call was made,
            //       and the tests expect that the publishers are ready.
            self.capturedUrls.append(url)
        }
    }
}


// MARK: async response triggers

extension FakeUrlSession {

    /// Trigger a random joke response from `get()`.
    ///
    /// Note that subjects and their associated publisher behave as a one-and-done, and so
    /// a subject is removed from the stack as soon as it is used.
    /// - parameters:
    ///  - joke: The joke returned from the `get()` request. If `nil`, an error response is thrown.
    func triggerJokeResponse(with joke: ChuckNorrisJoke?) {
        guard jokeSubjects.count > 0 else {
            Logger.api.error("Joke response can not be triggered because there are no pending requests.")
            return
        }

        let subject = jokeSubjects.removeFirst()
        subject.send(joke)
    }

    /// Trigger a random joke response from `get()`.
    ///
    /// Note that subjects and their associated publisher behave as a one-and-done, and so
    /// a subject is removed from the stack as soon as it is used.
    /// - parameters:
    ///  - categories: The categories returned from the `get()` request. If `nil`, an error response is thrown.
    func triggerCategoriesResponse(with categories: [String]?) {
        guard categoriesSubjects.count > 0 else {
            Logger.api.error("Categories response can not be triggered because there are no pending requests.")
            return
        }

        categoriesSubjects[0].send(categories)
        categoriesSubjects.removeFirst()
    }
}


// MARK: - Private Helpers

private extension FakeUrlSession {

    func resume<Model>(continuation: CheckedContinuation<Model, Error>,
                   on publisher: AnyPublisher<Model?, Never>) {
        publisher
            .first() // note that we never want to receive more than one item from this publisher
            .sink { response in
                Logger.api.debug("received response: \(String(describing: response))")
                if let response = response {
                    continuation.resume(returning: response)
                }
                else {
                    continuation.resume(throwing: Self.requestError)
                }
            }
            .store(in: &cancellables)
    }
}

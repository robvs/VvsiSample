//  Copyright © 2024 Rob Vander Sloot
//

@testable import VvsiSample
import Combine
import Foundation

class FakeUrlSession: AppUrlSessionHandling {

    /// the error that is thrown by `get()` when a failure response is triggered
    static let requestError = AppUrlSession.RequestError.serverResponse(code: 404)

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
                print("FakeUrlSession went out of scope")
                return
            }

            print("url.path(): \(url.path())")
            if url.path() == ChuckNorrisIoRequest.getRandomJoke(category: nil).url.path() {
                print("random joke url: \(url.absoluteString)")

                let subject = PassthroughSubject<ChuckNorrisJoke?, Never>()
                let publisher = subject.eraseToAnyPublisher()
                jokeSubjects.append(subject)

                publisher
                    .first()  // take only the first one because the next call to this function with start another subscriber.
                    .sink { joke in
                        print("received joke: \(String(describing: joke))")
                        if let joke = joke as? Model {
                            continuation.resume(returning: joke)
                        }
                        else {
                            continuation.resume(throwing: Self.requestError)
                        }
                    }
                    .store(in: &cancellables)
            }
            else if url.path() == ChuckNorrisIoRequest.getCategories.url.path() {
                print("categories url: \(url.absoluteString)")

                let subject = PassthroughSubject<[String]?, Never>()
                let publisher = subject.eraseToAnyPublisher()
                categoriesSubjects.append(subject)

                publisher
                    .first()  // take only the first one because the next call to this function with start another subscriber.
                    .sink { categories in
                        print("received categories: \(String(describing: categories))")
                        if let categories = categories as? Model  {
                            continuation.resume(returning: categories)
                        }
                        else {
                            continuation.resume(throwing: Self.requestError)
                        }
                    }
                    .store(in: &cancellables)
            }
            else {
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
            print("ERROR: Joke response can not be triggered because there are no pending requests.")
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
            print("ERROR: Categories response can not be triggered because there are no pending requests.")
            return
        }

        categoriesSubjects[0].send(categories)
        categoriesSubjects.removeFirst()
    }
}

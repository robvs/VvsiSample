//  Copyright © 2024 Rob Vander Sloot
//

@testable import VvsiSample
import Combine
import Foundation

class FakeUrlSession: AppUrlSessionHandling {

    private (set) var capturedUrls: [URL] = []
    private let jokePublisher: AnyPublisher<ChuckNorrisJoke?, Never>
    private let categoriesPublisher: AnyPublisher<[String]?, Never>
    private var cancellables: [Combine.AnyCancellable] = []

    /// Init a new instance of `FakeUrlSession`.
    /// - parameters:
    ///  - jokePublisher: Triggers the result of a `get()` random joke request.
    ///  - categoriesPublisher: Triggers the result of a `get()` categories request.
    init(jokePublisher: AnyPublisher<ChuckNorrisJoke?, Never>,
         categoriesPublisher: AnyPublisher<[String]?, Never>) {
        self.jokePublisher = jokePublisher
        self.categoriesPublisher = categoriesPublisher
    }

    func get<Model>(from url: URL) async throws -> Model where Model : Decodable {
        return try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<Model, Error>) in
            guard let self = self else {
                print("FakeUrlSession went out of scope")
                return
            }

            print("url.path(): \(url.path())")
            if url.path() == ChuckNorrisIoRequest.getRandomJoke(category: nil).url.path() {
                print("random joke url: \(url.absoluteString)")
                self.jokePublisher
                    .first()  // take only the first one because the next call to this function with start another subscriber.
                    .sink { joke in
                        print("received joke: \(String(describing: joke))")
                        if let joke = joke as? Model {
                            continuation.resume(returning: joke)
                        }
                        else {
                            continuation.resume(throwing: AppUrlSession.RequestError.serverResponse(code: 404))
                        }
                    }
                    .store(in: &cancellables)
            }
            else if url.path() == ChuckNorrisIoRequest.getCategories.url.path() {
                print("categories url: \(url.absoluteString)")
                self.categoriesPublisher
                    .first()  // take only the first one because the next call to this function with start another subscriber.
                    .sink { categories in
                        print("received categories: \(String(describing: categories))")
                        if let categories = categories as? Model  {
                            continuation.resume(returning: categories)
                        }
                        else {
                            continuation.resume(throwing: AppUrlSession.RequestError.serverResponse(code: 404))
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

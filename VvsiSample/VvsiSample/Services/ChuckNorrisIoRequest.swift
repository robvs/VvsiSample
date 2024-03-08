//  Copyright © 2024 Rob Vander Sloot
//

import Foundation

// MARK: Request result types

typealias GetRandomJokeResult = Result<String, AppUrlSession.RequestError>
typealias GetRandomJokesResult = Result<[String], AppUrlSession.RequestError>
typealias GetCategoriesResult = Result<[String], AppUrlSession.RequestError>

/// Defines request data for web service calls to `chucknorris.io`.
enum ChuckNorrisIoRequest {

    // MARK: Static properties

    /// Base url for the `chucknorris.io` web service.
    ///
    /// Note: The force unwrap is "safe" to do here because we can be certain that the URL string will parse.
    static let baseUrl = URL(string: "https://api.chucknorris.io")!

    // MARK: Available API requests

    /// Get a random joke for the given category. If `category` is `nil`, get any random joke.
    ///
    /// Sample response:
    /// ```
    /// {
    ///    "icon_url" : "https://assets.chucknorris.host/img/avatar/chuck-norris.png",
    ///    "id" : "lrFg32FrT1WaZdiPqQW8wA",
    ///    "url" : "",
    ///    "value" : "Chuck Norris once held one nostril shut while blowing an incredible snot volley from the other nostril. This action caused an epiphany among toy manufacturers that directly lead to the invention of the Nerf Blaster."
    /// }
    /// ```
    case getRandomJoke(category: String? = nil)

    /// Get all available categories.
    ///
    /// Sample response:
    /// `["animal","career","celebrity"]`
    case getCategories

    // MARK: Public helpers

    /// The full path URL for the request.
    var url: URL {
        switch self {
        case .getRandomJoke(let category):
            var requestUrl = Self.baseUrl.appending(path: "jokes/random")

            if let category = category {
                requestUrl.append(queryItems: [URLQueryItem(name: "category", value: category)])
            }

            return requestUrl

        case .getCategories:
            return Self.baseUrl.appending(path: "jokes/categories")
        }
    }
}

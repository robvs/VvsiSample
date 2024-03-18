//  Copyright © 2024 Rob Vander Sloot
//

import Foundation

/// Interface for an object that handles URL session requests.
protocol AppUrlSessionHandling {

    /// Perform a GET request on the given URL. If the request fails or the data
    /// can not be parsed, an error is thrown.
    /// - Parameter url: The URL on which to make the request.
    /// - Returns: An object containing the decoded response data.
    /// - Throws: `AppUrlSession.RequestError`
    func get<Model: Decodable>(from url: URL) async throws -> Model
}

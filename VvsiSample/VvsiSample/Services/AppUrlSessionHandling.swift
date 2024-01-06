//  Copyright © 2024 Rob Vander Sloot
//

import Foundation

/// Interface for an object that handles URL session requests.
protocol AppUrlSessionHandling {

    /// Perform a GET request on the given url.
    /// - parameter url: The URL on which to make the request.
    /// - returns: An object containing the response data. An `Error` is thrown if
    /// the request fails or the response data can not be decoded.
    func get<Model: Decodable>(from url: URL) async throws -> Model
}

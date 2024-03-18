//  Copyright © 2024 Rob Vander Sloot
//

import Foundation

/// Model definition for the data that is returned by a `getRandomJoke` request.
///
/// Sample response JSON:
/// ```
/// {
///    "icon_url" : "https://assets.chucknorris.host/img/avatar/chuck-norris.png",
///    "id" : "lrFg32FrT1WaZdiPqQW8wA",
///    "url" : "",
///    "value" : "Chuck Norris once held one nostril shut while blowing an incredible snot volley from the other nostril. This action caused an epiphany among toy manufacturers that directly lead to the invention of the Nerf Blaster."
/// }
/// ```
struct ChuckNorrisJoke: Codable, Equatable {
    let iconUrl: String?
    let id: String
    let url: String
    let value: String
}

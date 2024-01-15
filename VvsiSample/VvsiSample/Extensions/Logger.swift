//  Copyright © 2024 Rob Vander Sloot
//

import OSLog

extension Logger {

    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Used for logging view-related messages
    static let view = Logger(subsystem: subsystem, category: "view")

    /// Used for logging api-related messages
    static let api = Logger(subsystem: subsystem, category: "api")
}

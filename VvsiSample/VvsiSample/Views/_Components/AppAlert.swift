//  Copyright © 2024 Rob Vander Sloot
//

import UIKit
import SwiftUI

/// Defines and creates alerts that may be displayed by the app.
final class AppAlert {

    /// The types of alerts that can be displayed.
    enum AlertType: Equatable {

        /// No alert. This is used to allow an `AlertType` value to be non-optional.
        case none

        /// Unexpected error
        case unexpected

        /// An error occurred when making a network/web request.
        case networkRequestError

        /// The title that is displayed on the alert.
        var alertTitle: String? {
            switch self {
            case .none:
                return nil

            case .unexpected:
                return "Unexpected Error"

            case .networkRequestError:
                return "Request Error"
            }
        }

        /// The message that is displayed on the alert.
        var alertMessage: String {
            switch self {
            case .none, .unexpected:
                return "An unexpected error occurred."

            case .networkRequestError:
                return "A network data request failed."
            }
        }

        /// Create an alert for this alert type.
        func createAlert(okAction: @escaping (() -> Void) = {}) -> Alert {
            return AppAlert.createAlert(type: self, okAction: okAction)
        }
    }

    /// Create an alert for the given alert type.
    static func createAlert(type: AlertType,
                            okAction: @escaping (() -> Void) = {}) -> Alert {
        let title = Text(type.alertTitle ?? type.alertMessage)
        let message: Text? = type.alertTitle == nil ? nil : Text(type.alertMessage)

        return Alert(title: title,
                     message: message,
                     dismissButton: .default(Text("OK"), action: okAction))
    }
}

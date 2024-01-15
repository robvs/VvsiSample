//  Copyright © 2024 Rob Vander Sloot
//

import Foundation
import OSLog

/// This is a wrapper around URLSession that provides a simplified API specific to this app.
class AppUrlSession: AppUrlSessionHandling {

    static let shared = AppUrlSession()

    private let session: URLSession

    private init() {
        session = URLSession.shared
    }

    func get<Model: Decodable>(from url: URL) async throws -> Model {
        let urlRequest = URLRequest(url: url)
        let response: (data: Data, urlResponse: URLResponse)

        do {
            // Make the web request and parse the response.
            response = try await session.data(for: urlRequest, delegate: nil)
        }
        catch {
            Logger.api.error("session.data() threw an error: \(error.localizedDescription)")
            throw RequestError.unexpectedError(error)
        }

        return try parse(response.data, urlResponse: response.urlResponse)
    }
}


// MARK: - Private Helpers

private extension AppUrlSession {

    func parse<Model: Decodable>(_ data: Data, urlResponse: URLResponse) throws -> Model {
        guard let urlResponse = urlResponse as? HTTPURLResponse else {
            Logger.api.critical("The received URLResponse as not an HTTPURLResponse. \(urlResponse)")
            throw RequestError.unexpected("HTTPURLResponse was expected")
        }

        guard 200...299 ~= urlResponse.statusCode else {
            Logger.api.error("Failure response code: \(urlResponse.statusCode)")
            throw RequestError.serverResponse(code: urlResponse.statusCode)
        }

        guard !data.isEmpty else {
            Logger.api.error("API request succeeded but the response data is empty")
            throw RequestError.unexpected("API request succeeded but the response data is empty")
        }

        // the response data is expected to be JSON. parse it into a model object.
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(Model.self, from: data)
        }
        catch let decodingError as DecodingError {
            let dataString = String(data: data, encoding: .utf8) ?? ""
            Logger.api.error("Data could not be decoded: \(dataString)")
            throw RequestError.unexpectedError(decodingError)
        }
        catch {
            Logger.api.error("Unexpected error type: \(error)")
            throw RequestError.unexpectedError(error)
        }
    }
}

// MARK: - AppError extension

extension AppUrlSession {

    enum RequestError: Error {
        case unexpected(_ description: String)
        case unexpectedError(_ error: Error)
        case serverResponse(code: Int)

        var code: Int {
            switch self {
            case .unexpected: -1
            case .unexpectedError: -2
            case .serverResponse(let code): code
            }
        }

        var localizedDescription: String {
            switch self {
            case .unexpected(let description): description
            case .unexpectedError(let error): error.localizedDescription
            case .serverResponse(let code): "A data request error occurred. (code: \(code))"
            }
        }
    }
}

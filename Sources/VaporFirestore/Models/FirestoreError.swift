import Foundation
import Vapor


public struct FirestoreErrorResponse: Error, Codable {
    public struct FirestoreErrorResponseBody: Codable, Sendable {
        public let code: Int
        public let message: String
        public let status: String
    }
    
    public let error : FirestoreErrorResponseBody
}

public enum FirestoreError: Error {
    case requestFailed
    case networkError(Error)
    case invalidResponse(HTTPStatus)
    case tokenExpired
    case signing
    case parseFailed(data: String)
    case response(error: FirestoreErrorResponse)
}

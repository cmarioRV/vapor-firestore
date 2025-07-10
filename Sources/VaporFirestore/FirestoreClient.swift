//
//  FirestoreRequest.swift
//  App
//
//  Created by Ash Thwaites on 02/04/2019.
//

import Vapor
import JWTKit
import JWT

protocol FirestoreClient {
    func getToken() async throws -> String
    func send<F: Decodable>(method: HTTPMethod, path: String, query: String, body: ByteBuffer, headers: HTTPHeaders) async throws -> F
}

class FirestoreAPIClient: FirestoreClient {
    private let decoder = JSONDecoder.firestore
    private let encoder = JSONEncoder.firestore
    private weak var app: Application!
    private let basePath: String
    private let baseUrl: URL
    private let email: String
    private let privateKey: String
    private var authTokenExpireAt: Date
    private var authToken: String
    let keys = JWTKeyCollection()
    private var isKeysInitialized = false

    init(app: Application) {
        self.basePath = "projects/\(app.firebaseConfig!.projectId)/databases/(default)/documents/"
        self.baseUrl = URL(string: "https://firestore.googleapis.com/v1/")!
        self.app = app
        self.email = app.firebaseConfig!.email
        self.privateKey = app.firebaseConfig!.privateKey.replacingOccurrences(of: "\\n", with: "\n")
        self.authTokenExpireAt = Date.distantPast
        self.authToken = ""
    }
    
    private func ensureKeysInitialized() async throws {
        guard !isKeysInitialized else { return }
        
        let key = try Insecure.RSA.PublicKey(pem: self.privateKey)
        await keys.add(rsa: key, digestAlgorithm: .sha256)
        isKeysInitialized = true
    }

    func getToken() async throws -> String {
        if (authTokenExpireAt > Date() ) {
            return authToken
        }
        
        try await ensureKeysInitialized()

        var req = ClientRequest()
        
        do
        {
            let payload = Firestore.Auth.Payload(iss: IssuerClaim(value: self.email))

            let jwtString = try await keys.sign(payload)
            
            var headers = HTTPHeaders([])
            headers.add(name: HTTPHeaders.Name.contentType, value: "application/x-www-form-urlencoded")
            
            let body = Firestore.Auth.Request(grantType: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion: jwtString)
            
            try req.content.encode(body, as: .urlEncodedForm)
            req.url = URI(string: "https://www.googleapis.com/oauth2/v4/token")
            req.method = .POST
            
            let response = try await app.client.send(req).get()
            let authResponse = try response.content.decode(Firestore.Auth.Response.self)
            self.authToken = authResponse.accessToken
            self.authTokenExpireAt = Date().addingTimeInterval(TimeInterval(authResponse.expiresIn - 10))
            return authResponse.accessToken
        } catch let decodingError as DecodingError {
            throw FirestoreError.parseFailed(data: (String(describing: decodingError.errorDescription)))
        } catch {
            throw FirestoreError.signing
        }
    }

    func send<F: Decodable>(method: HTTPMethod, path: String, query:String, body: ByteBuffer, headers: HTTPHeaders) async throws -> F {
        do
        {
            let accessToken = try await getToken()
            let clientResponse = try await self.send(method: method, path: path, query: query, body: body, headers: headers, accessToken: accessToken)
            let body = clientResponse.body ?? ByteBuffer()
            return try self.decoder.decode(F.self, from: body)
        } catch FirestoreError.tokenExpired {
            //TODO Retry getting token
            throw FirestoreError.tokenExpired
        } catch let decodingError as DecodingError {
            throw FirestoreError.parseFailed(data: (String(describing: decodingError.errorDescription)))
        }
    }

    private func send(method: HTTPMethod, path: String, query:String, body: ByteBuffer, headers: HTTPHeaders, accessToken: String) async throws -> ClientResponse {
        let url = (path.hasPrefix(basePath)) ? baseUrl : baseUrl.appendingPathComponent(basePath)
        let uri = url.appendingPathComponent(path).absoluteString

        var finalHeaders: HTTPHeaders = [:]
        finalHeaders.add(name: .contentType, value: HTTPMediaType.json.description)
        finalHeaders.add(name: .authorization, value: "Bearer \(accessToken)")
        headers.forEach { finalHeaders.replaceOrAdd(name: $0.name, value: $0.value) }
        
        do
        {
            let response = try await app.client.send(method, headers: finalHeaders, to: "\(uri)?\(query)") { $0.body = body }
            guard (200...299).contains(response.status.code) else {
                if response.status.code == 401 {
                    throw FirestoreError.tokenExpired
                }
                
                if let responseBody = response.body {
                    do {
                        let errorResponse = try self.decoder.decode(FirestoreErrorResponse.self, from: responseBody)
                        throw errorResponse
                    } catch {
                        throw FirestoreError.invalidResponse(response.status)
                    }
                } else {
                    throw FirestoreError.invalidResponse(response.status)
                }
            }
            return response
        } catch let clientError {
            throw FirestoreError.networkError(clientError)
        }
    }
}


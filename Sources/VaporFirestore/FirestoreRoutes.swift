//
//  FirestoreRoutes.swift
//  App
//
//  Created by Ash Thwaites on 02/04/2019.
//

import Vapor

public struct FirestoreResource {
    private weak var app: Application!
    private var client: FirestoreClient

    init(app: Application) {
        self.app = app
        self.client = FirestoreAPIClient(app: app)
    }

    public func getDocument<T: Decodable>(path: String, query: String? = nil, mask: [String]? = nil) async throws -> Firestore.Document<T> {
        
        var finalQuery = ""
        
        if let query = query {
            finalQuery.append(query)
        }
        
        if let mask = mask {
            let maskQuery = mask.map({ "updateMask.fieldPaths=\($0)" }).joined(separator: "&")
            finalQuery.append(maskQuery)
        }
        
        return try await client.send(
            method: .GET,
            path: path,
            query: finalQuery,
            body: ByteBuffer(),
            headers: [:])
    }
    
    public func deleteDocument<T: Decodable>(path: String) async throws -> T {
        return try await client.send(
            method: .DELETE,
            path: path,
            query: "",
            body: ByteBuffer(),
            headers: [:])
    }

    public func listDocuments<T: Decodable>(path: String, query: String? = nil) async throws -> [Firestore.Document<T>] {
        return try await client.send(
            method: .GET,
            path: path,
            query: query ?? "",
            body: ByteBuffer(),
            headers: [:])
    }
    
    public func listDocumentsPaginated<T: Decodable>(path: String, query: String? = nil) async throws -> Firestore.List.Response<T> {
        return try await client.send(
            method: .GET,
            path: path,
            query: query ?? "",
            body: ByteBuffer(),
            headers: [:]
        )
    }

    public func createDocument<T: Codable>(path: String, name: String? = nil, fields: T) async throws -> Firestore.Document<T> {
        var query = ""
        if let safeName = name {
            query += "documentId=\(safeName)"
        }
        
        let requestBody = try JSONEncoder.firestore.encode(["fields": fields]).convertToHTTPBody()
        return try await client.send(
            method: .POST,
            path: path,
            query: query,
            body: requestBody,
            headers: [:])
    }

    public func updateDocument<T: Codable>(path: String, fields: T, updateMask: [String]?) async throws -> Firestore.Document<T> {
        var queryParams = ""
        if let updateMask = updateMask {
            queryParams = updateMask.map({ "updateMask.fieldPaths=\($0)" }).joined(separator: "&")
        }
        
        let requestBody = try JSONEncoder.firestore.encode(["fields": fields]).convertToHTTPBody()
        return try await client.send(
            method: .PATCH,
            path: path,
            query: queryParams,
            body: requestBody,
            headers: [:])
    }

}

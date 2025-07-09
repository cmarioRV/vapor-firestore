//
//  Provider.swift
//  App
//
//  Created by Ash Thwaites on 02/04/2019.
//

import Vapor

public struct FirestoreConfig : Sendable {
    public struct FirestoreConfigKey: StorageKey {
        public typealias Value = FirestoreConfig
    }
    
    public var projectId: String
    public var email: String
    public var privateKey: String
    
    public init(projectId: String, email: String, privateKey: String) {
        self.projectId = projectId
        self.email = email
        self.privateKey = privateKey
    }
}

public struct FirestoreService {
    public var firestore: FirestoreResource

    internal init(app: Application) {
        self.firestore = FirestoreResource(app: app)
    }
}

public extension Application {
    var firestoreService: FirestoreService { FirestoreService(app: self) }
    var firebaseConfig: FirestoreConfig? {
        get {
            return storage[FirestoreConfig.FirestoreConfigKey.self]
        }
        set {
            storage[FirestoreConfig.FirestoreConfigKey.self] = newValue
        }
    }
}

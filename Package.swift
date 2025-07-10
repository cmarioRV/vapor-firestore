// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "vapor-firestore",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "VaporFirestore", targets: ["VaporFirestore"]),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "5.1.2"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "8.0.0"),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "5.2.0"),
    ],
    targets: [
        .target(name: "VaporFirestore", dependencies: [
            .product(name: "Vapor", package: "vapor"),
            .product(name: "JWT", package: "jwt"),
            .product(name: "JWTKit", package: "jwt-kit"),
        ]),
        .testTarget(name: "VaporFirestoreTests", dependencies: [
            .target(name: "VaporFirestore"),
            .product(name: "Nimble", package: "Nimble"),
        ])
    ]
)


// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AeroAPI",
    platforms: [.iOS(.v15), .macOS(.v11)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AeroAPI",
            targets: ["AeroAPI"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(url: "https://github.com/michaeleisel/ZippyJSON.git", from: "1.2.6"),
         .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.0.0")),
         .package(url: "https://github.com/malcommac/SwiftDate.git", .upToNextMajor(from: "7.0.0")),
         .package(url: "https://github.com/sindresorhus/Defaults.git", .upToNextMajor(from: "8.0.0")),
         .package(path: "../NomadUtilities")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "AeroAPI",
            dependencies: [
                "Alamofire",
                "ZippyJSON",
                "SwiftDate",
                "Defaults",
                "NomadUtilities"
            ],
            path: "packages/aeroapi-swift/Sources/AeroAPI",
            resources: [
                .copy("Databases/airports.json"),
                .copy("Databases/airlines.json"),
                .copy("Databases/aircraft.json"),
                .copy("Models/Aircrafts/Aircraft.xcassets"),
                .copy("Models/Airlines/Airlines.xcassets")
            ]
        ),
        .testTarget(
            name: "AeroAPITests",
            dependencies: [
                "AeroAPI"
            ],
            path: "packages/aeroapi-swift/Tests/AeroAPITests"),
    ]
)

// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "BrowserBranch",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "BrowserBranch", targets: ["BrowserBranch"])
    ],
    targets: [
        .executableTarget(
            name: "BrowserBranch",
            path: "Sources/BrowserBranch"
        ),
        .testTarget(
            name: "BrowserBranchTests",
            dependencies: ["BrowserBranch"],
            path: "Tests/BrowserBranchTests"
        )
    ]
)

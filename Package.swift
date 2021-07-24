// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "SSTableViewPresenter",
    platforms: [
        .iOS(.v8)
    ],
    products: [
        .library(
            name: "SSTableViewPresenter",
            targets: ["SSTableViewPresenter"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/dSunny90/SendingState.git",
            from: "0.1.0"
        )
    ],
    targets: [
        .target(
            name: "SSTableViewPresenter",
            dependencies: [
                "SendingState"
            ]
        ),
        .testTarget(
            name: "SSTableViewPresenterTests",
            dependencies: ["SSTableViewPresenter"]
        )
    ]
)

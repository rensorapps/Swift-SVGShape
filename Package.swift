// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SVGShape",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SVGShape",
            targets: ["SVGShape"]),
    ],
//    dependencies: [
//        .package(url: "https://github.com/exyte/SVGView.git", from: "1.0.6")
//    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SVGShape"
//            ,
//            dependencies: [
//                .product(name: "SVGView", package: "SVGView")
//            ]
        ),
        .testTarget(
            name: "SVGShapeTests",
            dependencies: ["SVGShape"]),
    ]
)

for target in package.targets {
  target.swiftSettings = target.swiftSettings ?? []
  target.swiftSettings?.append(
    .unsafeFlags([
      "-enable-bare-slash-regex"
    ])
  )
}

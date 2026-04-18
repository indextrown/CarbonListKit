// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "CarbonListKit",
  platforms: [
    .iOS(.v13)
  ],
  products: [
    .library(
      name: "CarbonListKit",
      targets: ["CarbonListKit"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/ra1028/DifferenceKit.git", from: "1.3.0")
  ],
  targets: [
    .target(
      name: "CarbonListKit",
      dependencies: ["DifferenceKit"]
    ),
    .testTarget(
      name: "CarbonListKitTests",
      dependencies: ["CarbonListKit"]
    )
  ]
)

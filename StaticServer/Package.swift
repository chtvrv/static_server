// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "StaticServer",
  targets: [
    .systemLibrary(name: "libevent", pkgConfig: "libevent"),
    .target(
      name: "StaticServer",
      dependencies: ["libevent"]),
  ]
)

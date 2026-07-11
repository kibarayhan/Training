// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "TrainingApp",
    products: [
        .library(name: "TrainingCore", targets: ["TrainingCore"]),
        .library(name: "TrainingFIT", targets: ["TrainingFIT"]),
        .library(name: "TrainingSync", targets: ["TrainingSync"]),
        .executable(name: "demo", targets: ["demo"]),
    ],
    targets: [
        .target(name: "TrainingCore"),
        .target(name: "TrainingFIT", dependencies: ["TrainingCore"]),
        .target(name: "TrainingSync", dependencies: ["TrainingCore"]),
        .executableTarget(name: "demo", dependencies: ["TrainingCore", "TrainingFIT", "TrainingSync"]),
        .testTarget(name: "TrainingCoreTests", dependencies: ["TrainingCore"]),
        .testTarget(name: "TrainingFITTests", dependencies: ["TrainingFIT"]),
        .testTarget(name: "TrainingSyncTests", dependencies: ["TrainingSync"]),
    ]
)

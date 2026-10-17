// swift-tools-version: 5.10
import PackageDescription

// FichasCore tiene la lógica de dominio (calificación, sesiones, repetición).
// No depende de SwiftUI, así que sus pruebas corren en macOS y en Linux (CI).
let package = Package(
    name: "FichasCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "FichasCore", targets: ["FichasCore"]),
    ],
    targets: [
        .target(
            name: "FichasCore",
            path: "Sources/FichasCore"
        ),
        .testTarget(
            name: "FichasCoreTests",
            dependencies: ["FichasCore"],
            path: "Tests/FichasCoreTests"
        ),
    ]
)

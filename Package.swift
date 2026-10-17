// swift-tools-version: 5.10
import PackageDescription

// FichasCore tiene la lógica de dominio (calificación, sesiones, repetición).
// No depende de SwiftUI, así que sus pruebas corren en macOS y en Linux (CI).
// FichasDatos tiene la persistencia con SwiftData. SwiftData solo existe en
// plataformas de Apple: en Linux el target compila vacío (`#if canImport(SwiftData)`).
let package = Package(
    name: "FichasCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "FichasCore", targets: ["FichasCore"]),
        .library(name: "FichasDatos", targets: ["FichasDatos"]),
    ],
    targets: [
        .target(
            name: "FichasCore",
            path: "Sources/FichasCore"
        ),
        .target(
            name: "FichasDatos",
            dependencies: ["FichasCore"],
            path: "Sources/FichasDatos"
        ),
        .testTarget(
            name: "FichasCoreTests",
            dependencies: ["FichasCore"],
            path: "Tests/FichasCoreTests"
        ),
        .testTarget(
            name: "FichasDatosTests",
            dependencies: ["FichasDatos"],
            path: "Tests/FichasDatosTests"
        ),
    ]
)

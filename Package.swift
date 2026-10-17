// swift-tools-version: 5.10
import PackageDescription

// FichasCore tiene la lógica de dominio (calificación, sesiones, repetición).
// No depende de SwiftUI, así que sus pruebas corren en macOS y en Linux (CI).
// FichasDatos tiene la persistencia con SwiftData. SwiftData solo existe en
// plataformas de Apple: en Linux el target compila vacío (`#if canImport(SwiftData)`).
// FichasFSRS programa los repasos con swift-fsrs, detrás del protocolo Programador de FichasCore.
let package = Package(
    name: "FichasCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "FichasCore", targets: ["FichasCore"]),
        .library(name: "FichasDatos", targets: ["FichasDatos"]),
        .library(name: "FichasFSRS", targets: ["FichasFSRS"]),
    ],
    dependencies: [
        // Fork con el arreglo de open-spaced-repetition/swift-fsrs#38, fijado a un commit.
        // Volver a upstream cuando se fusione y haya release.
        .package(url: "https://github.com/serandmoncas/swift-fsrs.git", revision: "c210b075d6650ab61482301e8d149afbe4206ede"),
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
        .target(
            name: "FichasFSRS",
            dependencies: ["FichasCore", .product(name: "FSRS", package: "swift-fsrs")],
            path: "Sources/FichasFSRS"
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
        .testTarget(
            name: "FichasFSRSTests",
            dependencies: ["FichasFSRS"],
            path: "Tests/FichasFSRSTests"
        ),
    ]
)

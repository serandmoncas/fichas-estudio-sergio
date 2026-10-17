import Foundation

/// Lee los casos de prueba compartidos del repo de especificación (submódulo `especificacion/`).
enum CasosCompartidos {
    static let carpeta: URL = {
        // Tests/FichasCoreTests/CasosCompartidos.swift -> raíz del paquete
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("especificacion/pruebas/casos")
    }()

    static func cargar<Entrada: Decodable, Esperado: Decodable>(
        _ archivo: String,
        entrada: Entrada.Type,
        esperado: Esperado.Type
    ) throws -> ArchivoCasos<Entrada, Esperado> {
        let url = carpeta.appendingPathComponent(archivo)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ErrorCasos.faltaArchivo(url.path)
        }
        let datos = try Data(contentsOf: url)
        return try JSONDecoder().decode(ArchivoCasos<Entrada, Esperado>.self, from: datos)
    }
}

enum ErrorCasos: Error, CustomStringConvertible {
    case faltaArchivo(String)

    var description: String {
        switch self {
        case .faltaArchivo(let ruta):
            return "No se encontró \(ruta). ¿Corriste `git submodule update --init`?"
        }
    }
}

struct ArchivoCasos<Entrada: Decodable, Esperado: Decodable>: Decodable {
    let id: String
    let estado: String
    let casos: [Caso<Entrada, Esperado>]
}

struct Caso<Entrada: Decodable, Esperado: Decodable>: Decodable {
    let id: String
    let descripcion: String
    let entrada: Entrada
    let esperado: Esperado
}

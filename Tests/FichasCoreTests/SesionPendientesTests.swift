import XCTest
@testable import FichasCore

/// Corre cada caso de especificacion/pruebas/casos/sesion-pendientes.json.
final class SesionPendientesTests: XCTestCase {
    struct Ficha: Decodable {
        let id: String
        let proximo_repaso: String?
    }

    struct Entrada: Decodable {
        let hoy: String
        let limite_nuevas: Int
        let fichas: [Ficha]
    }

    struct Esperado: Decodable {
        let repasos: [String]
        let cantidad_nuevas: Int
    }

    func testCasosCompartidos() throws {
        let archivo = try CasosCompartidos.cargar("sesion-pendientes.json", entrada: Entrada.self, esperado: Esperado.self)
        XCTAssertFalse(archivo.casos.isEmpty, "sesion-pendientes.json no tiene casos")

        for caso in archivo.casos {
            let e = caso.entrada
            let fichas = e.fichas.map { FichaProgramada(id: $0.id, proximoRepaso: $0.proximo_repaso) }
            do {
                let obtenido = try seleccionarPendientes(hoy: e.hoy, fichas: fichas, limiteNuevas: e.limite_nuevas)
                // El orden de los repasos no forma parte del contrato.
                XCTAssertEqual(Set(obtenido.repasos), Set(caso.esperado.repasos), "\(caso.id): \(caso.descripcion)")
                XCTAssertEqual(obtenido.repasos.count, caso.esperado.repasos.count, "\(caso.id): repasos duplicados")
                XCTAssertEqual(obtenido.cantidadNuevas, caso.esperado.cantidad_nuevas, "\(caso.id): \(caso.descripcion)")
            } catch {
                XCTFail("\(caso.id): \(caso.descripcion) → \(error)")
            }
        }
    }
}

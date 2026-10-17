import XCTest
@testable import FichasCore

/// Corre cada caso de especificacion/pruebas/casos/calificacion.json.
final class CalificacionTests: XCTestCase {
    struct Entrada: Decodable {
        let tipo_calificacion: TipoCalificacion
        let calificacion: CalificacionOriginal
        let tiempo_agotado: Bool
    }

    struct Esperado: Decodable {
        let calificacion_fsrs: CalificacionFSRS?
        let error: String?
    }

    func testCasosCompartidos() throws {
        let archivo = try CasosCompartidos.cargar("calificacion.json", entrada: Entrada.self, esperado: Esperado.self)
        XCTAssertFalse(archivo.casos.isEmpty, "calificacion.json no tiene casos")

        for caso in archivo.casos {
            let e = caso.entrada
            do {
                let obtenido = try traducirCalificacion(
                    tipo: e.tipo_calificacion,
                    calificacion: e.calificacion,
                    tiempoAgotado: e.tiempo_agotado
                )
                if let esperado = caso.esperado.calificacion_fsrs {
                    XCTAssertEqual(obtenido, esperado, "\(caso.id): \(caso.descripcion)")
                } else {
                    XCTFail("\(caso.id): se esperaba el error \(caso.esperado.error ?? "?") y se obtuvo \(obtenido)")
                }
            } catch ErrorCalificacion.calificacionInvalida {
                XCTAssertEqual(caso.esperado.error, "calificacion_invalida", "\(caso.id): error inesperado")
            } catch {
                XCTFail("\(caso.id): \(caso.descripcion) → \(error)")
            }
        }
    }
}

extension CalificacionOriginal: Decodable {
    /// En el JSON la calificación es un número (escala 1 a 5) o el texto "pasa" / "no_pasa".
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let n = try? c.decode(Int.self) {
            self = .escala(n)
            return
        }
        switch try c.decode(String.self) {
        case "pasa": self = .pasa
        case "no_pasa": self = .noPasa
        case let otro:
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Calificación desconocida: \(otro)")
        }
    }
}

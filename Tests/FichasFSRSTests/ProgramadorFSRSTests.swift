import FichasCore
import XCTest
@testable import FichasFSRS

/// Programación con FSRS (issue #1 de la especificación, todavía sin decidir).
final class ProgramadorFSRSTests: XCTestCase {
    let programador = ProgramadorFSRS()

    /// Vector propuesto como FSRS-001: FSRS-6 por defecto, retención 0,9, sin fuzz, solo días enteros.
    /// Verificado con ts-fsrs 5.4.2 y con swift-fsrs + el arreglo de open-spaced-repetition/swift-fsrs#38.
    /// Cada paso pasa por EstadoRepaso, así que también prueba la conversión de fechas y de estado.
    func testConformidadConElVectorCompartido() throws {
        let calificaciones: [CalificacionFSRS] = [
            .bien, .bien, .bien, .bien, .bien, .bien,
            .otraVez, .otraVez, .bien, .bien, .bien, .bien, .bien,
        ]
        var hoy = "2026-10-17"
        var estado: EstadoRepaso?
        var intervalos: [Int] = []
        for calificacion in calificaciones {
            let nuevo = try programador.programar(estado, calificacion: calificacion, hoy: hoy)
            intervalos.append(nuevo.diasProgramados)
            estado = nuevo
            hoy = nuevo.proximoRepaso
        }
        XCTAssertEqual(intervalos, [3, 14, 57, 196, 586, 1559, 10, 1, 3, 5, 9, 15, 25])
    }

    func testUnaFichaNuevaCalificadaBienVuelveEnTresDias() throws {
        let estado = try programador.programar(nil, calificacion: .bien, hoy: "2026-10-17")
        XCTAssertEqual(estado.ultimoRepaso, "2026-10-17")
        XCTAssertEqual(estado.proximoRepaso, "2026-10-20")
        XCTAssertEqual(estado.repasos, 1)
        XCTAssertEqual(estado.olvidos, 0)
    }

    func testOtraVezEnUnaFichaEnRepasoCuentaComoOlvido() throws {
        let aprendida = try programador.programar(nil, calificacion: .bien, hoy: "2026-10-17")
        let olvidada = try programador.programar(aprendida, calificacion: .otraVez, hoy: aprendida.proximoRepaso)
        XCTAssertEqual(olvidada.olvidos, 1)
        XCTAssertEqual(olvidada.diasProgramados, 1)
    }

    func testUnaFechaMalEscritaEsUnError() {
        XCTAssertThrowsError(try programador.programar(nil, calificacion: .bien, hoy: "2026-1-7")) { error in
            XCTAssertEqual(error as? ErrorProgramador, .fechaInvalida("2026-1-7"))
        }
    }
}

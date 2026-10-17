import XCTest
@testable import FichasCore

/// Resumen al terminar una sesión (REQ-030). Qué se muestra es la pregunta abierta 16;
/// esto es lo mínimo, en la escala común de FSRS.
final class ResumenSesionTests: XCTestCase {
    func testCuentaLasRespuestasEnLaEscalaDeFSRS() {
        let resumen = resumirSesion([
            RespuestaResumible(id: "a", calificacion: .escala(1), tiempoAgotado: false, tiempoRespuestaSegundos: 4),
            RespuestaResumible(id: "b", calificacion: .escala(4), tiempoAgotado: false, tiempoRespuestaSegundos: 6),
            RespuestaResumible(id: "c", calificacion: .pasa, tiempoAgotado: false, tiempoRespuestaSegundos: 2),
            // CAL-008: con el tiempo agotado cuenta como Otra vez aunque se haya puesto un 5.
            RespuestaResumible(id: "d", calificacion: .escala(5), tiempoAgotado: true, tiempoRespuestaSegundos: 30),
        ])
        XCTAssertEqual(resumen.total, 4)
        XCTAssertEqual(resumen.porCalificacion, [.otraVez: 2, .bien: 2])
        XCTAssertEqual(resumen.paraRepasar, ["a", "d"])
        XCTAssertEqual(resumen.tiempoPromedioSegundos, 10.5)
    }

    func testUnaSesionSinRespuestasNoTienePromedio() {
        let resumen = resumirSesion([RespuestaResumible<String>]())
        XCTAssertEqual(resumen.total, 0)
        XCTAssertEqual(resumen.porCalificacion, [:])
        XCTAssertNil(resumen.tiempoPromedioSegundos)
    }
}

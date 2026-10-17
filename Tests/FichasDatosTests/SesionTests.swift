#if canImport(SwiftData)
import FichasCore
import Foundation
import SwiftData
import XCTest
@testable import FichasDatos

/// Sesión y Respuesta (especificacion/specs/02-modelo-de-datos.md, REQ-020 a REQ-022, REQ-026, REQ-030).
final class SesionTests: XCTestCase {
    var contexto: ModelContext!
    var ciencias: Categoria!
    var ficha: Ficha!

    override func setUpWithError() throws {
        contexto = try ModelContext(Almacen.contenedorEnMemoria())
        ciencias = Categoria(nombre: "Ciencias")
        contexto.insert(ciencias)
        ficha = try Ficha(pregunta: "¿Cuál es el planeta más cercano al Sol?", respuesta: "Mercurio",
                          categoria: ciencias, tipoCalificacion: .escala1a5)
        contexto.insert(ficha)
    }

    func testGuardaUnaSesionConSusRespuestas() throws {
        let inicio = Date(timeIntervalSince1970: 1_800_000_000)
        let sesion = Sesion(inicio: inicio, categorias: [ciencias], fichasSolicitadas: 10)
        contexto.insert(sesion)
        sesion.respuestas.append(Respuesta(ficha: ficha, mostradaEn: inicio, calificacion: .escala(4),
                                           tiempoRespuestaSegundos: 6.5, tiempoAgotado: false))
        sesion.respuestas.append(Respuesta(ficha: ficha, mostradaEn: inicio, calificacion: .noPasa,
                                           tiempoRespuestaSegundos: 30, tiempoAgotado: true))
        try contexto.save()

        let leida = try XCTUnwrap(contexto.fetch(FetchDescriptor<Sesion>()).first)
        XCTAssertTrue(leida.enCurso)
        XCTAssertEqual(leida.fichasSolicitadas, 10)
        XCTAssertEqual(leida.categorias.map(\.nombre), ["Ciencias"])
        XCTAssertEqual(Set(leida.respuestas.map(\.calificacion)), [.escala(4), .noPasa])
        XCTAssertEqual(ficha.respuestas.count, 2)
    }

    func testTerminarUnaSesionGuardaLaHoraDeFin() {
        let sesion = Sesion(inicio: .now, categorias: [ciencias], fichasSolicitadas: 5)
        let fin = Date.now.addingTimeInterval(600)
        sesion.terminar(en: fin)
        XCTAssertFalse(sesion.enCurso)
        XCTAssertEqual(sesion.fin, fin)
    }

    func testEliminarUnaSesionBorraSusRespuestas() throws {
        let sesion = Sesion(inicio: .now, categorias: [ciencias], fichasSolicitadas: 1)
        contexto.insert(sesion)
        sesion.respuestas.append(Respuesta(ficha: ficha, mostradaEn: .now, calificacion: .pasa,
                                           tiempoRespuestaSegundos: 3, tiempoAgotado: false))
        try contexto.save()

        contexto.delete(sesion)
        try contexto.save()

        XCTAssertEqual(try contexto.fetchCount(FetchDescriptor<Respuesta>()), 0)
    }

    /// El registro de la sesión (REQ-030) se conserva aunque se borre la ficha.
    func testEliminarUnaFichaConservaLasRespuestasDeLaSesion() throws {
        let sesion = Sesion(inicio: .now, categorias: [ciencias], fichasSolicitadas: 1)
        contexto.insert(sesion)
        sesion.respuestas.append(Respuesta(ficha: ficha, mostradaEn: .now, calificacion: .escala(2),
                                           tiempoRespuestaSegundos: 8, tiempoAgotado: false))
        try contexto.save()

        contexto.delete(ficha)
        try contexto.save()

        let respuesta = try XCTUnwrap(contexto.fetch(FetchDescriptor<Respuesta>()).first)
        XCTAssertNil(respuesta.ficha)
        XCTAssertEqual(respuesta.calificacion, .escala(2))
    }
}
#endif

#if canImport(SwiftData)
import FichasCore
import SwiftData
import XCTest
@testable import FichasDatos

/// Campos de Ficha (especificacion/specs/02-modelo-de-datos.md, REQ-014 a REQ-017).
final class FichaTests: XCTestCase {
    var contexto: ModelContext!
    var ciencias: Categoria!

    override func setUpWithError() throws {
        contexto = try ModelContext(Almacen.contenedorEnMemoria())
        ciencias = Categoria(nombre: "Ciencias")
        contexto.insert(ciencias)
    }

    func testGuardaCamposAdicionalesTipoDeCalificacionYTiempo() throws {
        let ficha = try Ficha(
            pregunta: "¿Qué gas respiran las plantas de noche?",
            respuesta: "Oxígeno",
            categoria: ciencias,
            camposAdicionales: [CampoAdicional(nombre: "Pista", texto: "El mismo que nosotros")],
            tipoCalificacion: .pasaNoPasa,
            tiempoMaximoSegundos: 30
        )
        contexto.insert(ficha)
        try contexto.save()

        let leida = try XCTUnwrap(contexto.fetch(FetchDescriptor<Ficha>()).first)
        XCTAssertEqual(leida.camposAdicionales, [CampoAdicional(nombre: "Pista", texto: "El mismo que nosotros")])
        XCTAssertEqual(leida.tipoCalificacion, .pasaNoPasa)
        XCTAssertTrue(leida.conTiempo)
        XCTAssertEqual(leida.tiempoMaximoSegundos, 30)
    }

    func testSinTiempoMaximoLaFichaNoTieneLimite() throws {
        let ficha = try Ficha(pregunta: "¿Cuántas patas tiene una araña?", respuesta: "Ocho",
                              categoria: ciencias, tipoCalificacion: .escala1a5)
        XCTAssertFalse(ficha.conTiempo)
        XCTAssertNil(ficha.tiempoMaximoSegundos)
    }

    func testLaSubcategoriaDebeSerDeLaMismaCategoria() throws {
        let historia = Categoria(nombre: "Historia")
        contexto.insert(historia)
        let independencia = Subcategoria(nombre: "Independencia")
        historia.subcategorias.append(independencia)

        XCTAssertThrowsError(
            try Ficha(pregunta: "¿Qué es un volcán?", respuesta: "Una abertura en la Tierra",
                      categoria: ciencias, subcategoria: independencia, tipoCalificacion: .escala1a5)
        ) { error in
            XCTAssertEqual(error as? ErrorDatos, .subcategoriaDeOtraCategoria)
        }
    }

    func testMoverUnaFichaAOtraCategoriaLeQuitaLaSubcategoria() throws {
        let fisica = Subcategoria(nombre: "Física")
        ciencias.subcategorias.append(fisica)
        let ficha = try Ficha(pregunta: "¿Qué es la gravedad?", respuesta: "La fuerza que atrae los cuerpos",
                              categoria: ciencias, subcategoria: fisica, tipoCalificacion: .escala1a5)
        contexto.insert(ficha)
        let repaso = Categoria(nombre: "Repaso")
        contexto.insert(repaso)

        ficha.mover(a: repaso)

        XCTAssertIdentical(ficha.categoria, repaso)
        XCTAssertNil(ficha.subcategoria)
    }
}
#endif

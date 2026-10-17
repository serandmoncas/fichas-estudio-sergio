#if canImport(SwiftData)
import FichasCore
import Foundation
import SwiftData
import XCTest
@testable import FichasDatos

/// Importar un mazo en el formato propuesto en el issue #6 de la especificación (todavía sin decidir).
final class ImportadorMazoTests: XCTestCase {
    var contexto: ModelContext!

    override func setUpWithError() throws {
        contexto = try ModelContext(Almacen.contenedorEnMemoria())
    }

    let mazo = Data("""
    {
      "formato": "fichas-mazo",
      "version": 1,
      "nombre": "Aprendizaje",
      "categorias": [
        { "id": "c1", "nombre": "Memoria y cerebro", "subcategorias": [{ "id": "s1", "nombre": "Olvido" }] }
      ],
      "fichas": [
        {
          "id": "f1",
          "pregunta": "¿Qué muestra la curva del olvido?",
          "respuesta": "Que se olvida rápido al principio y más lento después",
          "categoria": "c1",
          "subcategoria": "s1",
          "campos_adicionales": [{ "nombre": "Ejemplo", "texto": "Un repaso al día siguiente" }],
          "tipo_calificacion": "escala_1_5",
          "tiempo_maximo_segundos": null,
          "cita": { "fuente": "ebb", "ubicacion": "cap. 7" }
        },
        {
          "id": "f2",
          "pregunta": "¿El sueño ayuda a consolidar recuerdos?",
          "respuesta": "Sí",
          "categoria": "c1",
          "tipo_calificacion": "pasa_no_pasa"
        }
      ],
      "fuentes": [{ "id": "ebb", "titulo": "Sobre la memoria", "autor": "Ebbinghaus", "anio": 1885 }]
    }
    """.utf8)

    func testImportaCategoriasSubcategoriasYFichasConSuFuente() throws {
        let resultado = try ImportadorMazo.importar(mazo, en: contexto)
        XCTAssertEqual(resultado, ResultadoImportacion(categoriasNuevas: 1, fichasNuevas: 2, fichasRepetidas: 0))

        let fichas = try contexto.fetch(FetchDescriptor<Ficha>(sortBy: [SortDescriptor(\.pregunta)]))
        let curva = try XCTUnwrap(fichas.first { $0.pregunta.contains("curva") })
        XCTAssertEqual(curva.categoria?.nombre, "Memoria y cerebro")
        XCTAssertEqual(curva.subcategoria?.nombre, "Olvido")
        XCTAssertEqual(curva.tipoCalificacion, .escala1a5)
        // La cita se muestra al estudiar como un campo adicional más.
        XCTAssertEqual(curva.camposAdicionales, [
            CampoAdicional(nombre: "Ejemplo", texto: "Un repaso al día siguiente"),
            CampoAdicional(nombre: "Fuente", texto: "Ebbinghaus (1885). Sobre la memoria, cap. 7"),
        ])
        XCTAssertEqual(fichas.first { $0.pregunta.contains("sueño") }?.tipoCalificacion, .pasaNoPasa)
    }

    func testLaFuenteIncluyeRevistaYEnlaceSiLosHay() throws {
        let conRevista = Data("""
        { "formato": "fichas-mazo", "version": 1, "nombre": "x",
          "categorias": [{ "id": "c1", "nombre": "Memoria" }],
          "fichas": [{ "id": "f1", "pregunta": "p", "respuesta": "r", "categoria": "c1",
                       "tipo_calificacion": "escala_1_5", "cita": { "fuente": "m" } }],
          "fuentes": [{ "id": "m", "titulo": "The magical number seven", "autor": "Miller", "anio": 1956,
                        "revista": "Psychological Review", "doi": "10.1037/h0043158" }] }
        """.utf8)
        _ = try ImportadorMazo.importar(conRevista, en: contexto)
        let ficha = try XCTUnwrap(contexto.fetch(FetchDescriptor<Ficha>()).first)
        XCTAssertEqual(ficha.camposAdicionales, [
            CampoAdicional(nombre: "Fuente", texto: "Miller (1956). The magical number seven. Psychological Review"),
            CampoAdicional(nombre: "Enlace", texto: "https://doi.org/10.1037/h0043158"),
        ])
    }

    func testUnaFuenteSinDOIMuestraSuURL() throws {
        let conURL = Data("""
        { "formato": "fichas-mazo", "version": 1, "nombre": "x",
          "categorias": [{ "id": "c1", "nombre": "Claude" }],
          "fichas": [{ "id": "f1", "pregunta": "p", "respuesta": "r", "categoria": "c1",
                       "tipo_calificacion": "escala_1_5", "cita": { "fuente": "d" } }],
          "fuentes": [{ "id": "d", "titulo": "Claude Code overview", "autor": "Anthropic",
                        "url": "https://docs.claude.com/en/docs/claude-code/overview" }] }
        """.utf8)
        _ = try ImportadorMazo.importar(conURL, en: contexto)
        let ficha = try XCTUnwrap(contexto.fetch(FetchDescriptor<Ficha>()).first)
        XCTAssertEqual(ficha.camposAdicionales.last,
                       CampoAdicional(nombre: "Enlace", texto: "https://docs.claude.com/en/docs/claude-code/overview"))
    }

    func testImportarDosVecesNoDuplica() throws {
        _ = try ImportadorMazo.importar(mazo, en: contexto)
        let segunda = try ImportadorMazo.importar(mazo, en: contexto)
        XCTAssertEqual(segunda, ResultadoImportacion(categoriasNuevas: 0, fichasNuevas: 0, fichasRepetidas: 2))
        XCTAssertEqual(try contexto.fetchCount(FetchDescriptor<Categoria>()), 1)
        XCTAssertEqual(try contexto.fetchCount(FetchDescriptor<Ficha>()), 2)
    }

    func testUnArchivoDeOtroFormatoEsUnError() {
        let otro = Data(#"{ "formato": "otra-cosa", "version": 1, "nombre": "x", "categorias": [], "fichas": [] }"#.utf8)
        XCTAssertThrowsError(try ImportadorMazo.importar(otro, en: contexto)) { error in
            XCTAssertEqual(error as? ErrorDatos, .mazoInvalido("formato desconocido: otra-cosa"))
        }
    }

    func testUnaFichaConCategoriaDesconocidaNoImportaNada() throws {
        let roto = Data("""
        { "formato": "fichas-mazo", "version": 1, "nombre": "x",
          "categorias": [{ "id": "c1", "nombre": "Una" }],
          "fichas": [{ "id": "f1", "pregunta": "p", "respuesta": "r", "categoria": "c9", "tipo_calificacion": "escala_1_5" }] }
        """.utf8)
        XCTAssertThrowsError(try ImportadorMazo.importar(roto, en: contexto)) { error in
            XCTAssertEqual(error as? ErrorDatos, .mazoInvalido("la ficha f1 usa la categoría c9, que no está en el mazo"))
        }
        XCTAssertEqual(try contexto.fetchCount(FetchDescriptor<Categoria>()), 0)
    }
}
#endif

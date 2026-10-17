#if canImport(SwiftData)
import SwiftData
import XCTest
@testable import FichasDatos

/// Eliminar categorías (REQ-012) sin dejar fichas sin categoría (REQ-014).
/// La regla de bloquear no está en la especificación; ver PREGUNTAS-ABIERTAS en el repo de especificación.
final class EliminarCategoriaTests: XCTestCase {
    var contexto: ModelContext!

    override func setUpWithError() throws {
        contexto = try ModelContext(Almacen.contenedorEnMemoria())
    }

    func testNoSePuedeEliminarUnaCategoriaConFichas() throws {
        let categoria = Categoria(nombre: "Ciencias")
        contexto.insert(categoria)
        contexto.insert(Ficha(pregunta: "¿Qué planeta es el más grande?", respuesta: "Júpiter", categoria: categoria))
        try contexto.save()

        XCTAssertThrowsError(try contexto.eliminar(categoria)) { error in
            XCTAssertEqual(error as? ErrorDatos, .categoriaConFichas)
        }
        XCTAssertEqual(try contexto.fetchCount(FetchDescriptor<Categoria>()), 1)
        XCTAssertEqual(try contexto.fetchCount(FetchDescriptor<Ficha>()), 1)
    }

    func testEliminarUnaCategoriaSinFichasBorraTambienSusSubcategorias() throws {
        let categoria = Categoria(nombre: "Historia")
        contexto.insert(categoria)
        categoria.subcategorias.append(Subcategoria(nombre: "Independencia"))
        try contexto.save()

        try contexto.eliminar(categoria)

        XCTAssertEqual(try contexto.fetchCount(FetchDescriptor<Categoria>()), 0)
        XCTAssertEqual(try contexto.fetchCount(FetchDescriptor<Subcategoria>()), 0)
    }

    func testEliminarUnaSubcategoriaDejaSusFichasEnLaCategoria() throws {
        let categoria = Categoria(nombre: "Matemáticas")
        contexto.insert(categoria)
        let fracciones = Subcategoria(nombre: "Fracciones")
        categoria.subcategorias.append(fracciones)
        let ficha = Ficha(pregunta: "¿Cuánto es 1/2 + 1/4?", respuesta: "3/4", categoria: categoria, subcategoria: fracciones)
        contexto.insert(ficha)
        try contexto.save()

        contexto.delete(fracciones)
        try contexto.save()

        XCTAssertEqual(try contexto.fetchCount(FetchDescriptor<Ficha>()), 1)
        XCTAssertNil(ficha.subcategoria)
        XCTAssertEqual(ficha.categoria?.nombre, "Matemáticas")
    }
}
#endif

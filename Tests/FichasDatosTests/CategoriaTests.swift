#if canImport(SwiftData)
import SwiftData
import XCTest
@testable import FichasDatos

/// Persistencia de Categoría y Subcategoría (especificacion/specs/02-modelo-de-datos.md, REQ-012, REQ-013).
final class CategoriaTests: XCTestCase {
    func testGuardaYLeeUnaCategoriaConSusSubcategorias() throws {
        let contexto = try ModelContext(Almacen.contenedorEnMemoria())
        let categoria = Categoria(nombre: "Matemáticas")
        contexto.insert(categoria)
        categoria.subcategorias.append(Subcategoria(nombre: "Fracciones"))
        try contexto.save()

        let leidas = try contexto.fetch(FetchDescriptor<Categoria>())
        XCTAssertEqual(leidas.map(\.nombre), ["Matemáticas"])
        XCTAssertEqual(leidas.first?.subcategorias.map(\.nombre), ["Fracciones"])
        XCTAssertEqual(leidas.first?.subcategorias.first?.categoria?.nombre, "Matemáticas")
    }
}
#endif

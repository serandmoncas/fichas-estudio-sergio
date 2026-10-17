#if canImport(SwiftData)
import SwiftData
import XCTest
@testable import FichasDatos

/// Datos de ejemplo para probar la app a mano (argumento de arranque `-datos-ejemplo`).
final class DatosDeEjemploTests: XCTestCase {
    var contexto: ModelContext!

    override func setUpWithError() throws {
        contexto = try ModelContext(Almacen.contenedorEnMemoria())
    }

    func testCargaCategoriasFichasYSesionesValidas() throws {
        try DatosDeEjemplo.cargar(en: contexto, hoy: Date(timeIntervalSince1970: 1_800_000_000))

        let categorias = try contexto.fetch(FetchDescriptor<Categoria>())
        let fichas = try contexto.fetch(FetchDescriptor<Ficha>())
        XCTAssertGreaterThanOrEqual(categorias.count, 3)
        XCTAssertGreaterThanOrEqual(fichas.count, 12)
        // Ejercitan las dos escalas, el límite de tiempo, los campos adicionales y las subcategorías.
        XCTAssertTrue(fichas.contains { $0.tipoCalificacion == .escala1a5 })
        XCTAssertTrue(fichas.contains { $0.tipoCalificacion == .pasaNoPasa })
        XCTAssertTrue(fichas.contains { $0.conTiempo })
        XCTAssertTrue(fichas.contains { !$0.camposAdicionales.isEmpty })
        XCTAssertTrue(fichas.contains { $0.subcategoria != nil })
        // REQ-014: toda subcategoría es de la categoría de su ficha.
        for ficha in fichas where ficha.subcategoria != nil {
            XCTAssertIdentical(ficha.subcategoria?.categoria, ficha.categoria, ficha.pregunta)
        }

        let sesiones = try contexto.fetch(FetchDescriptor<Sesion>())
        XCTAssertGreaterThanOrEqual(sesiones.count, 2)
        XCTAssertTrue(sesiones.allSatisfy { !$0.enCurso && !$0.respuestas.isEmpty })
    }

    func testNoCargaNadaSiYaHayCategorias() throws {
        contexto.insert(Categoria(nombre: "Mía"))
        try contexto.save()

        try DatosDeEjemplo.cargar(en: contexto, hoy: .now)

        XCTAssertEqual(try contexto.fetch(FetchDescriptor<Categoria>()).map(\.nombre), ["Mía"])
        XCTAssertEqual(try contexto.fetchCount(FetchDescriptor<Ficha>()), 0)
    }
}
#endif

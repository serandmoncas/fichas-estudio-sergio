import XCTest
@testable import FichasCore

/// Selección de fichas para una sesión manual (REQ-021 a REQ-023).
/// No hay casos compartidos para esto todavía; se proponen a la especificación.
final class SeleccionSesionTests: XCTestCase {
    let fichas = [
        FichaCandidata(id: "m1", categoria: "mate", subcategoria: "fracciones"),
        FichaCandidata(id: "m2", categoria: "mate", subcategoria: nil),
        FichaCandidata(id: "c1", categoria: "ciencias", subcategoria: "planetas"),
        FichaCandidata(id: "c2", categoria: "ciencias", subcategoria: "animales"),
        FichaCandidata(id: "h1", categoria: "historia", subcategoria: nil),
    ]
    var generador = GeneradorFijo(semilla: 42)

    func testEntranLasFichasDeLasCategoriasElegidas() {
        let ids = seleccionarFichasSesion(fichas: fichas, categorias: ["mate"], subcategorias: [],
                                          cantidad: 10, generador: &generador)
        XCTAssertEqual(Set(ids), ["m1", "m2"])
    }

    /// REQ-021: "una o varias categorías, subcategorías o ambas". Se toma la unión.
    func testUnaSubcategoriaElegidaSumaSusFichasSinRepetir() {
        let ids = seleccionarFichasSesion(fichas: fichas, categorias: ["mate"], subcategorias: ["planetas", "fracciones"],
                                          cantidad: 10, generador: &generador)
        XCTAssertEqual(ids.count, 3)
        XCTAssertEqual(Set(ids), ["m1", "m2", "c1"])
    }

    /// REQ-022: entran a lo sumo las fichas pedidas.
    func testNoEntranMasFichasQueLasPedidas() {
        let ids = seleccionarFichasSesion(fichas: fichas, categorias: ["mate", "ciencias", "historia"], subcategorias: [],
                                          cantidad: 2, generador: &generador)
        XCTAssertEqual(ids.count, 2)
    }

    /// Pregunta abierta 14. Regla provisional: si hay menos fichas que las pedidas, entran todas.
    func testSiHayMenosFichasQueLasPedidasEntranTodas() {
        let ids = seleccionarFichasSesion(fichas: fichas, categorias: ["historia"], subcategorias: [],
                                          cantidad: 10, generador: &generador)
        XCTAssertEqual(ids, ["h1"])
    }

    /// REQ-023: orden aleatorio. Al recortar, tampoco entran siempre las mismas.
    func testElOrdenYLasFichasRecortadasSonAleatorios() {
        var ordenes = Set<[String]>()
        var recortes = Set<Set<String>>()
        for semilla in UInt64(1)...20 {
            var g = GeneradorFijo(semilla: semilla)
            let todas = seleccionarFichasSesion(fichas: fichas, categorias: ["mate", "ciencias", "historia"],
                                                subcategorias: [], cantidad: 10, generador: &g)
            XCTAssertEqual(Set(todas), ["m1", "m2", "c1", "c2", "h1"])
            ordenes.insert(todas)
            let dos = seleccionarFichasSesion(fichas: fichas, categorias: ["mate", "ciencias", "historia"],
                                              subcategorias: [], cantidad: 2, generador: &g)
            recortes.insert(Set(dos))
        }
        XCTAssertGreaterThan(ordenes.count, 1, "el orden no cambia")
        XCTAssertGreaterThan(recortes.count, 1, "siempre entran las mismas fichas")
    }
}

/// Generador con semilla (SplitMix64), para que el orden aleatorio sea repetible en las pruebas.
struct GeneradorFijo: RandomNumberGenerator {
    var estado: UInt64
    init(semilla: UInt64) { estado = semilla }
    mutating func next() -> UInt64 {
        estado &+= 0x9E37_79B9_7F4A_7C15
        var z = estado
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

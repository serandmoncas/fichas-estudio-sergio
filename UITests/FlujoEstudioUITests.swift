import XCTest

/// Recorre las pantallas mínimas de especificacion/specs/04-interfaz.md en el simulador de iOS.
/// La app arranca con `-pruebas-ui`: datos vacíos en memoria.
final class FlujoEstudioUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-pruebas-ui"]
        app.launch()
    }

    /// Categorías → Fichas → Nueva sesión → Estudio → Resumen → Historial.
    func testCrearUnaFichaEstudiarlaYVerlaEnElHistorial() {
        crearCategoria("Ciencias")
        abrir("Ciencias")
        abrir("Fichas")
        crearFicha(pregunta: "¿Cuántas patas tiene una araña?", respuesta: "Ocho")
        volverAlInicio()

        abrir("Elegir qué estudiar")
        app.switches["Ciencias"].firstMatch.switches.firstMatch.tap()
        app.buttons["Empezar"].tap()

        esperar(app.staticTexts["¿Cuántas patas tiene una araña?"])
        app.buttons["Mostrar respuesta"].tap()
        esperar(app.staticTexts["Ocho"])
        app.buttons["4"].tap()

        esperar(app.staticTexts["Terminaste por hoy"])
        XCTAssertTrue(conTexto("1 de 10 fichas").exists)
        XCTAssertEqual(valor(de: "Bien"), "1")
        volverAlInicio()

        abrir("Historial")
        esperar(conTexto("1 fichas"))
    }

    /// REQ-012 con la regla de bloquear: una categoría con fichas no se elimina.
    func testNoSePuedeEliminarUnaCategoriaConFichas() {
        crearCategoria("Historia")
        abrir("Historia")
        abrir("Fichas")
        crearFicha(pregunta: "¿Quién escribió el Quijote?", respuesta: "Cervantes")
        volver()
        volver()

        fila("Historia").swipeLeft()
        app.buttons["Eliminar"].tap()

        esperar(app.alerts["No se puede eliminar"])
        app.alerts.buttons["Entendido"].tap()
        XCTAssertTrue(fila("Historia").exists)
    }

    // MARK: - Pasos

    private func crearCategoria(_ nombre: String) {
        app.buttons["Categorías"].tap()
        app.buttons["Nueva categoría"].tap()
        let alerta = app.alerts["Nueva categoría"]
        esperar(alerta)
        alerta.textFields.firstMatch.typeText(nombre)
        alerta.buttons["Guardar"].tap()
        esperar(fila(nombre))
    }

    private func crearFicha(pregunta: String, respuesta: String) {
        app.buttons["Nueva ficha"].tap()
        let campoPregunta = app.textFields["Pregunta"]
        esperar(campoPregunta)
        campoPregunta.tap()
        campoPregunta.typeText(pregunta)
        app.textFields["Respuesta"].tap()
        app.textFields["Respuesta"].typeText(respuesta)
        app.buttons["Guardar"].tap()
        esperar(conTexto(pregunta))
    }

    private func abrir(_ nombre: String) {
        let elemento = fila(nombre)
        esperar(elemento)
        elemento.tap()
    }

    /// Un botón por su texto. Las filas con `LabeledContent` juntan etiqueta y valor ("Ciencias, 0").
    private func fila(_ nombre: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == %@ OR label BEGINSWITH %@", nombre, "\(nombre), ")).firstMatch
    }

    /// Cualquier elemento cuyo texto contenga `texto`.
    private func conTexto(_ texto: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", texto)).firstMatch
    }

    private func volver() {
        app.navigationBars.buttons["BackButton"].tap()
    }

    private func volverAlInicio() {
        // La lista de fichas también se titula "Fichas", así que se vuelve hasta que no haya botón de atrás.
        while app.navigationBars.buttons["BackButton"].exists {
            volver()
        }
    }

    /// El valor de una fila `LabeledContent`, que aparece como "Etiqueta, valor".
    private func valor(de etiqueta: String) -> String? {
        let texto = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "\(etiqueta), ")).firstMatch
        guard texto.waitForExistence(timeout: 5) else { return nil }
        return String(texto.label.dropFirst(etiqueta.count + 2))
    }

    private func esperar(_ elemento: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(elemento.waitForExistence(timeout: 5), "No apareció: \(elemento)", file: file, line: line)
    }
}

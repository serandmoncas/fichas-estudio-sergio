import XCTest

/// Recorre las pantallas mínimas de especificacion/specs/04-interfaz.md en el simulador de iOS.
/// La app arranca con `-pruebas-ui`: datos vacíos en memoria.
final class FlujoEstudioUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-pruebas-ui"]
        // Respaldo por si el sistema muestra algo encima (por ejemplo, el tutorial del teclado en un simulador nuevo).
        addUIInterruptionMonitor(withDescription: "Avisos del sistema") { alerta in
            for boton in ["Continue", "Continuar", "OK", "Aceptar", "Not Now", "Ahora no"] where alerta.buttons[boton].exists {
                alerta.buttons[boton].tap()
                return true
            }
            return false
        }
        app.launch()
    }

    /// Categorías → Fichas → Nueva sesión → Estudio → Resumen → Historial.
    func testCrearUnaFichaEstudiarlaYVerlaEnElHistorial() {
        crearCategoria("Ciencias")
        abrir("Ciencias")
        abrir("Fichas")
        crearFicha(pregunta: "¿Cuántas patas tiene una araña?", respuesta: "Ocho")
        volver(a: "Ciencias")
        volver(a: "Categorías")
        volver(a: "Fichas")

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
        volver(a: "Nueva sesión")
        volver(a: "Fichas")

        abrir("Historial")
        esperar(conTexto("1 fichas"))
    }

    /// REQ-012 con la regla de bloquear: una categoría con fichas no se elimina.
    func testNoSePuedeEliminarUnaCategoriaConFichas() {
        crearCategoria("Historia")
        abrir("Historia")
        abrir("Fichas")
        crearFicha(pregunta: "¿Quién escribió el Quijote?", respuesta: "Cervantes")
        volver(a: "Historia")
        volver(a: "Categorías")

        // A veces el primer deslizamiento no abre la fila (la pantalla sigue animando al volver).
        let eliminar = app.buttons["Eliminar"]
        for _ in 1...2 where !eliminar.exists {
            fila("Historia").swipeLeft()
            _ = eliminar.waitForExistence(timeout: 2)
        }
        eliminar.tap()

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
        escribir(pregunta, en: campoPregunta)
        escribir(respuesta, en: app.textFields["Respuesta"])
        app.buttons["Guardar"].tap()
        esperar(conTexto(pregunta))
    }

    private func abrir(_ nombre: String) {
        let elemento = fila(nombre)
        esperar(elemento)
        elemento.tap()
    }

    /// Escribe y comprueba que el campo quedó con el texto completo: el teclado en pantalla
    /// puede perder caracteres, y así el error dice cuál en lugar de fallar más adelante.
    private func escribir(_ texto: String, en campo: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        campo.tap()
        campo.typeText(texto)
        // Se busca de nuevo por el valor: `campo` se encontraba por el texto de ejemplo, que ya no está.
        let escrito = app.textFields.matching(NSPredicate(format: "value == %@", texto)).firstMatch
        if !escrito.exists {
            let valores = app.textFields.allElementsBoundByIndex.map { $0.value as? String ?? "" }
            XCTFail("El campo no quedó con \"\(texto)\". Campos: \(valores)", file: file, line: line)
        }
    }

    /// Un botón por su texto. Las filas con `LabeledContent` juntan etiqueta y valor ("Ciencias, 0").
    private func fila(_ nombre: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == %@ OR label BEGINSWITH %@", nombre, "\(nombre), ")).firstMatch
    }

    /// Cualquier elemento cuyo texto contenga `texto`.
    private func conTexto(_ texto: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", texto)).firstMatch
    }

    /// Toca el botón de atrás, que lleva el título de la pantalla anterior.
    /// (El identificador "BackButton" existe en iOS 26 pero no en iOS 18.)
    private func volver(a titulo: String) {
        let boton = app.navigationBars.buttons[titulo].firstMatch
        esperar(boton)
        boton.tap()
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

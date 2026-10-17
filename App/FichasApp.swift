import FichasDatos
import SwiftData
import SwiftUI

@main
struct FichasApp: App {
    let contenedor: ModelContainer

    init() {
        do {
            // Las pruebas de interfaz arrancan con datos vacíos en memoria, sin tocar los guardados.
            contenedor = ProcessInfo.processInfo.arguments.contains("-pruebas-ui")
                ? try Almacen.contenedorEnMemoria()
                : try Almacen.contenedor()
        } catch {
            // Sin almacenamiento la app no puede funcionar; mejor fallar al abrir que perder datos después.
            fatalError("No se pudo abrir el almacenamiento: \(error)")
        }
        #if DEBUG
        // Para probar a mano: carga fichas y sesiones de ejemplo si todavía no hay categorías.
        if ProcessInfo.processInfo.arguments.contains("-datos-ejemplo") {
            try? DatosDeEjemplo.cargar(en: contenedor.mainContext, hoy: .now)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            InicioView()
        }
        .modelContainer(contenedor)
    }
}

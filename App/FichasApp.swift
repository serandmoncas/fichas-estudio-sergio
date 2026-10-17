import FichasDatos
import SwiftData
import SwiftUI

@main
struct FichasApp: App {
    let contenedor: ModelContainer

    init() {
        do {
            contenedor = try Almacen.contenedor()
        } catch {
            // Sin almacenamiento la app no puede funcionar; mejor fallar al abrir que perder datos después.
            fatalError("No se pudo abrir el almacenamiento: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            InicioView()
        }
        .modelContainer(contenedor)
    }
}

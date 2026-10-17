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
        // Para cargar un mazo propio: `-importar-mazo Documents/mazo.json` (ruta relativa a la carpeta de la app).
        let argumentos = ProcessInfo.processInfo.arguments
        if let i = argumentos.firstIndex(of: "-importar-mazo"), argumentos.indices.contains(i + 1) {
            let ruta = argumentos[i + 1]
            let url = ruta.hasPrefix("/") ? URL(fileURLWithPath: ruta)
                : URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(ruta)
            do {
                let resultado = try ImportadorMazo.importar(Data(contentsOf: url), en: contenedor.mainContext)
                print("Mazo importado: \(resultado)")
            } catch {
                print("No se pudo importar \(url.path): \(error)")
            }
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

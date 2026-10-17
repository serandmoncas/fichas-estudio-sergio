// Persistencia con SwiftData. Ver Package.swift.
#if canImport(SwiftData)
import SwiftData

public enum Almacen {
    /// Todos los modelos que guarda la app.
    public static let esquema = Schema([Categoria.self, Subcategoria.self])

    /// Contenedor que vive solo en memoria, para pruebas y vistas previas.
    public static func contenedorEnMemoria() throws -> ModelContainer {
        try ModelContainer(for: esquema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }
}
#endif

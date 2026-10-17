// Categoría y Subcategoría (especificacion/specs/02-modelo-de-datos.md, REQ-012, REQ-013).
#if canImport(SwiftData)
import SwiftData

@Model
public final class Categoria {
    public var nombre: String
    @Relationship(inverse: \Subcategoria.categoria)
    public var subcategorias: [Subcategoria] = []

    public init(nombre: String) {
        self.nombre = nombre
    }
}

@Model
public final class Subcategoria {
    public var nombre: String
    public var categoria: Categoria?

    public init(nombre: String) {
        self.nombre = nombre
    }
}
#endif

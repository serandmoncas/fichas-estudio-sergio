// Categoría y Subcategoría (especificacion/specs/02-modelo-de-datos.md, REQ-012, REQ-013).
#if canImport(SwiftData)
import SwiftData

@Model
public final class Categoria {
    public var nombre: String
    @Relationship(deleteRule: .cascade, inverse: \Subcategoria.categoria)
    public var subcategorias: [Subcategoria] = []
    /// `.deny` impide borrar la categoría si tiene fichas; `ModelContext.eliminar(_:)` lo comprueba antes.
    @Relationship(deleteRule: .deny, inverse: \Ficha.categoria)
    public var fichas: [Ficha] = []

    public init(nombre: String) {
        self.nombre = nombre
    }
}

@Model
public final class Subcategoria {
    public var nombre: String
    public var categoria: Categoria?
    /// Al borrar la subcategoría, sus fichas quedan en la categoría (REQ-014 permite ficha sin subcategoría).
    @Relationship(deleteRule: .nullify, inverse: \Ficha.subcategoria)
    public var fichas: [Ficha] = []

    public init(nombre: String) {
        self.nombre = nombre
    }
}

public enum ErrorDatos: Error, Equatable {
    /// La categoría tiene fichas: hay que moverlas o borrarlas antes de eliminarla.
    case categoriaConFichas
}

extension ModelContext {
    /// Elimina la categoría con sus subcategorías. Falla si todavía tiene fichas.
    public func eliminar(_ categoria: Categoria) throws {
        guard categoria.fichas.isEmpty else { throw ErrorDatos.categoriaConFichas }
        delete(categoria)
        try save()
    }
}
#endif

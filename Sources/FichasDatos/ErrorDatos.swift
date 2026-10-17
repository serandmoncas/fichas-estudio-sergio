// Errores de la capa de persistencia.

public enum ErrorDatos: Error, Equatable {
    /// La categoría tiene fichas: hay que moverlas o borrarlas antes de eliminarla.
    case categoriaConFichas
    /// La subcategoría no pertenece a la categoría de la ficha (REQ-014).
    case subcategoriaDeOtraCategoria
    /// El archivo de mazo no tiene el formato esperado, o se contradice.
    case mazoInvalido(String)
}

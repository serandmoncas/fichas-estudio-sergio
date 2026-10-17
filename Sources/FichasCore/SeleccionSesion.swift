// Selección de fichas para una sesión manual (REQ-021 a REQ-023).

/// Lo mínimo de una ficha que hace falta para decidir si entra a una sesión manual.
/// `ID` es el identificador que use la app (por ejemplo, el de SwiftData).
public struct FichaCandidata<ID: Hashable>: Equatable {
    public let id: ID
    public let categoria: ID
    public let subcategoria: ID?

    public init(id: ID, categoria: ID, subcategoria: ID?) {
        self.id = id
        self.categoria = categoria
        self.subcategoria = subcategoria
    }
}

/// Elige las fichas de una sesión manual.
///
/// - Parameters:
///   - categorias: categorías elegidas (REQ-021).
///   - subcategorias: subcategorías elegidas (REQ-021).
///   - cantidad: cuántas fichas pidió el estudiante (REQ-022).
///   - generador: fuente de aleatoriedad para el orden (REQ-023).
/// - Returns: los ids de las fichas, en el orden en que se muestran.
public func seleccionarFichasSesion<ID: Hashable, G: RandomNumberGenerator>(
    fichas: [FichaCandidata<ID>],
    categorias: Set<ID>,
    subcategorias: Set<ID>,
    cantidad: Int,
    generador: inout G
) -> [ID] {
    let elegidas = fichas.filter { ficha in
        categorias.contains(ficha.categoria) || ficha.subcategoria.map(subcategorias.contains) == true
    }
    // Mezclar antes de recortar: si no, al pedir menos fichas entrarían siempre las primeras.
    return elegidas.shuffled(using: &generador).prefix(cantidad).map(\.id)
}

// Ficha (especificacion/specs/02-modelo-de-datos.md, REQ-010 a REQ-014).
#if canImport(SwiftData)
import SwiftData

@Model
public final class Ficha {
    public var pregunta: String
    public var respuesta: String
    /// Siempre tiene valor (REQ-014). SwiftData exige que las relaciones sean opcionales.
    public var categoria: Categoria?
    public var subcategoria: Subcategoria?

    public init(pregunta: String, respuesta: String, categoria: Categoria, subcategoria: Subcategoria? = nil) {
        self.pregunta = pregunta
        self.respuesta = respuesta
        self.categoria = categoria
        self.subcategoria = subcategoria
    }
}
#endif

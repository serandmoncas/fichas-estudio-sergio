// Datos de ejemplo para probar la app a mano. Se cargan con el argumento de arranque `-datos-ejemplo`.
// Contenido escolar genérico, sin nombres ni datos personales (regla de privacidad de la especificación).
#if canImport(SwiftData)
import FichasCore
import Foundation
import SwiftData

public enum DatosDeEjemplo {
    private struct FichaEjemplo {
        let pregunta: String
        let respuesta: String
        var subcategoria: String? = nil
        let tipo: TipoCalificacion
        var segundos: Int? = nil
        var campos: [CampoAdicional] = []
    }

    private struct CategoriaEjemplo {
        let nombre: String
        let subcategorias: [String]
        let fichas: [FichaEjemplo]
    }

    private static let categorias: [CategoriaEjemplo] = [
        CategoriaEjemplo(nombre: "Matemáticas", subcategorias: ["Fracciones", "Tablas"], fichas: [
            FichaEjemplo(pregunta: "¿Cuánto es 1/2 + 1/4?", respuesta: "3/4", subcategoria: "Fracciones", tipo: .escala1a5),
            FichaEjemplo(pregunta: "¿Qué fracción es mayor, 2/3 o 3/5?", respuesta: "2/3", subcategoria: "Fracciones", tipo: .escala1a5,
                         campos: [CampoAdicional(nombre: "Pista", texto: "Pásalas a quinceavos")]),
            FichaEjemplo(pregunta: "Simplifica 6/8", respuesta: "3/4", subcategoria: "Fracciones", tipo: .escala1a5,
                         campos: [CampoAdicional(nombre: "Pista", texto: "Divide arriba y abajo entre 2")]),
            FichaEjemplo(pregunta: "¿Cuánto es 7 × 8?", respuesta: "56", subcategoria: "Tablas", tipo: .escala1a5, segundos: 10),
            FichaEjemplo(pregunta: "¿Cuánto es 6 × 9?", respuesta: "54", subcategoria: "Tablas", tipo: .escala1a5, segundos: 10),
            FichaEjemplo(pregunta: "¿Cuánto es 12 × 12?", respuesta: "144", subcategoria: "Tablas", tipo: .escala1a5, segundos: 10),
        ]),
        CategoriaEjemplo(nombre: "Ciencias", subcategorias: ["Planetas", "Animales"], fichas: [
            FichaEjemplo(pregunta: "¿Cuál es el planeta más cercano al Sol?", respuesta: "Mercurio", subcategoria: "Planetas", tipo: .pasaNoPasa),
            FichaEjemplo(pregunta: "¿Qué planeta tiene los anillos más visibles?", respuesta: "Saturno", subcategoria: "Planetas", tipo: .pasaNoPasa,
                         campos: [CampoAdicional(nombre: "Pista", texto: "Es el sexto planeta")]),
            FichaEjemplo(pregunta: "¿Cuántos planetas tiene el sistema solar?", respuesta: "Ocho", subcategoria: "Planetas", tipo: .pasaNoPasa),
            FichaEjemplo(pregunta: "¿Cuántas patas tiene una araña?", respuesta: "Ocho", subcategoria: "Animales", tipo: .pasaNoPasa),
            FichaEjemplo(pregunta: "¿Cuál es el animal más grande que existe?", respuesta: "La ballena azul", subcategoria: "Animales", tipo: .pasaNoPasa),
            FichaEjemplo(pregunta: "¿Los murciélagos son aves o mamíferos?", respuesta: "Mamíferos", subcategoria: "Animales", tipo: .pasaNoPasa,
                         campos: [CampoAdicional(nombre: "Pista", texto: "Alimentan a sus crías con leche")]),
        ]),
        CategoriaEjemplo(nombre: "Geografía", subcategorias: [], fichas: [
            FichaEjemplo(pregunta: "¿Cuál es la capital de Colombia?", respuesta: "Bogotá", tipo: .pasaNoPasa),
            FichaEjemplo(pregunta: "¿Cuál es el río principal de Colombia?", respuesta: "El Magdalena", tipo: .pasaNoPasa),
            FichaEjemplo(pregunta: "¿En qué continente está Colombia?", respuesta: "América del Sur", tipo: .escala1a5, segundos: 15),
            FichaEjemplo(pregunta: "¿Qué océanos bañan las costas de Colombia?", respuesta: "El Pacífico y el Atlántico (por el mar Caribe)",
                         tipo: .escala1a5,
                         campos: [CampoAdicional(nombre: "Pista", texto: "Uno al occidente y otro al norte")]),
        ]),
    ]

    /// Carga categorías, fichas y dos sesiones pasadas. No hace nada si ya hay categorías,
    /// para no duplicar ni mezclarse con datos reales.
    public static func cargar(en contexto: ModelContext, hoy: Date) throws {
        guard try contexto.fetchCount(FetchDescriptor<Categoria>()) == 0 else { return }

        var fichas: [Ficha] = []
        for ejemplo in categorias {
            let categoria = Categoria(nombre: ejemplo.nombre)
            contexto.insert(categoria)
            var subcategorias: [String: Subcategoria] = [:]
            for nombre in ejemplo.subcategorias {
                let subcategoria = Subcategoria(nombre: nombre)
                categoria.subcategorias.append(subcategoria)
                subcategorias[nombre] = subcategoria
            }
            for f in ejemplo.fichas {
                let ficha = try Ficha(
                    pregunta: f.pregunta, respuesta: f.respuesta, categoria: categoria,
                    subcategoria: f.subcategoria.flatMap { subcategorias[$0] },
                    camposAdicionales: f.campos, tipoCalificacion: f.tipo, tiempoMaximoSegundos: f.segundos
                )
                contexto.insert(ficha)
                fichas.append(ficha)
            }
        }

        // Dos sesiones pasadas, para que el historial no aparezca vacío.
        let dia: TimeInterval = 24 * 60 * 60
        agregarSesion(en: contexto, inicio: hoy.addingTimeInterval(-2 * dia), fichas: Array(fichas[0..<4]),
                      calificaciones: [.escala(4), .escala(2), .escala(5), .escala(1)])
        agregarSesion(en: contexto, inicio: hoy.addingTimeInterval(-dia), fichas: Array(fichas[6..<11]),
                      calificaciones: [.pasa, .noPasa, .pasa, .pasa, .noPasa])
        try contexto.save()
    }

    private static func agregarSesion(en contexto: ModelContext, inicio: Date, fichas: [Ficha],
                                      calificaciones: [CalificacionOriginal]) {
        let sesion = Sesion(inicio: inicio, categorias: Array(Set(fichas.compactMap(\.categoria))),
                            fichasSolicitadas: fichas.count)
        contexto.insert(sesion)
        var momento = inicio
        for (ficha, calificacion) in zip(fichas, calificaciones) {
            sesion.respuestas.append(Respuesta(ficha: ficha, mostradaEn: momento, calificacion: calificacion,
                                               tiempoRespuestaSegundos: 6, tiempoAgotado: false))
            momento.addTimeInterval(20)
        }
        sesion.terminar(en: momento)
    }
}
#endif

// Importar un mazo en el formato propuesto en el issue #6 de la especificación.
// El formato todavía no está decidido: esto es un prototipo para probarlo con mazos reales.
#if canImport(SwiftData)
import FichasCore
import Foundation
import SwiftData

public struct ResultadoImportacion: Equatable, Sendable {
    public let categoriasNuevas: Int
    public let fichasNuevas: Int
    /// Fichas que ya estaban (misma pregunta en la misma categoría) y no se volvieron a crear.
    public let fichasRepetidas: Int
}

public enum ImportadorMazo {
    // MARK: - Formato del archivo

    private struct Mazo: Decodable {
        let formato: String
        let version: Int
        let nombre: String
        let categorias: [CategoriaMazo]
        let fichas: [FichaMazo]
        let fuentes: [FuenteMazo]?
    }

    private struct CategoriaMazo: Decodable {
        let id: String
        let nombre: String
        let subcategorias: [SubcategoriaMazo]?
    }

    private struct SubcategoriaMazo: Decodable {
        let id: String
        let nombre: String
    }

    private struct FichaMazo: Decodable {
        let id: String
        let pregunta: String
        let respuesta: String
        let categoria: String
        let subcategoria: String?
        let campos_adicionales: [CampoAdicional]?
        let tipo_calificacion: TipoCalificacion
        let tiempo_maximo_segundos: Int?
        let cita: Cita?
    }

    private struct Cita: Decodable {
        let fuente: String
        let ubicacion: String?
    }

    private struct FuenteMazo: Decodable {
        let id: String
        let titulo: String
        let autor: String?
        let anio: Int?
        let revista: String?
        let doi: String?
        let url: String?
    }

    // MARK: - Importar

    /// Agrega las categorías, subcategorías y fichas del mazo. Las categorías y subcategorías que ya
    /// existen (mismo nombre) se reutilizan, y una ficha con la misma pregunta en la misma categoría
    /// no se vuelve a crear, así que importar dos veces no duplica nada.
    /// Si el archivo tiene un error, no se importa nada.
    public static func importar(_ datos: Data, en contexto: ModelContext) throws -> ResultadoImportacion {
        let mazo: Mazo
        do {
            mazo = try JSONDecoder().decode(Mazo.self, from: datos)
        } catch {
            throw ErrorDatos.mazoInvalido("no se pudo leer el archivo: \(error)")
        }
        guard mazo.formato == "fichas-mazo" else { throw ErrorDatos.mazoInvalido("formato desconocido: \(mazo.formato)") }
        guard mazo.version == 1 else { throw ErrorDatos.mazoInvalido("versión no soportada: \(mazo.version)") }
        try validar(mazo)

        let fuentes = Dictionary(uniqueKeysWithValues: (mazo.fuentes ?? []).map { ($0.id, $0) })
        var existentes = Dictionary(try contexto.fetch(FetchDescriptor<Categoria>()).map { ($0.nombre, $0) },
                                    uniquingKeysWith: { primera, _ in primera })
        var categorias: [String: Categoria] = [:]
        var subcategorias: [String: Subcategoria] = [:]
        var categoriasNuevas = 0

        for c in mazo.categorias {
            let categoria: Categoria
            if let existente = existentes[c.nombre] {
                categoria = existente
            } else {
                categoria = Categoria(nombre: c.nombre)
                contexto.insert(categoria)
                existentes[c.nombre] = categoria
                categoriasNuevas += 1
            }
            categorias[c.id] = categoria
            for s in c.subcategorias ?? [] {
                if let existente = categoria.subcategorias.first(where: { $0.nombre == s.nombre }) {
                    subcategorias[s.id] = existente
                } else {
                    let subcategoria = Subcategoria(nombre: s.nombre)
                    categoria.subcategorias.append(subcategoria)
                    subcategorias[s.id] = subcategoria
                }
            }
        }

        var fichasNuevas = 0
        var fichasRepetidas = 0
        for f in mazo.fichas {
            let categoria = categorias[f.categoria]! // validar(_:) ya comprobó que existe.
            if categoria.fichas.contains(where: { $0.pregunta == f.pregunta }) {
                fichasRepetidas += 1
                continue
            }
            var campos = f.campos_adicionales ?? []
            if let cita = f.cita, let fuente = fuentes[cita.fuente] {
                campos.append(CampoAdicional(nombre: "Fuente", texto: texto(de: fuente, ubicacion: cita.ubicacion)))
                if let enlace = fuente.doi.map({ "https://doi.org/\($0)" }) ?? fuente.url {
                    campos.append(CampoAdicional(nombre: "Enlace", texto: enlace))
                }
            }
            let ficha = try Ficha(
                pregunta: f.pregunta, respuesta: f.respuesta, categoria: categoria,
                subcategoria: f.subcategoria.flatMap { subcategorias[$0] },
                camposAdicionales: campos, tipoCalificacion: f.tipo_calificacion,
                tiempoMaximoSegundos: f.tiempo_maximo_segundos
            )
            contexto.insert(ficha)
            fichasNuevas += 1
        }
        try contexto.save()
        return ResultadoImportacion(categoriasNuevas: categoriasNuevas, fichasNuevas: fichasNuevas,
                                    fichasRepetidas: fichasRepetidas)
    }

    /// Revisa que las referencias internas del archivo existan, antes de tocar el almacenamiento.
    private static func validar(_ mazo: Mazo) throws {
        let categorias = Set(mazo.categorias.map(\.id))
        var subcategoriaDe: [String: String] = [:]
        for c in mazo.categorias {
            for s in c.subcategorias ?? [] { subcategoriaDe[s.id] = c.id }
        }
        let fuentes = Set((mazo.fuentes ?? []).map(\.id))
        for f in mazo.fichas {
            guard categorias.contains(f.categoria) else {
                throw ErrorDatos.mazoInvalido("la ficha \(f.id) usa la categoría \(f.categoria), que no está en el mazo")
            }
            if let s = f.subcategoria, subcategoriaDe[s] != f.categoria {
                throw ErrorDatos.mazoInvalido("la ficha \(f.id) usa la subcategoría \(s), que no es de su categoría")
            }
            if let cita = f.cita, !fuentes.contains(cita.fuente) {
                throw ErrorDatos.mazoInvalido("la ficha \(f.id) cita la fuente \(cita.fuente), que no está en el mazo")
            }
        }
    }

    /// "Autor (año). Título. Revista, ubicación", con lo que haya.
    private static func texto(de fuente: FuenteMazo, ubicacion: String?) -> String {
        var texto = ""
        if let autor = fuente.autor { texto += autor }
        if let anio = fuente.anio { texto += texto.isEmpty ? "\(anio)" : " (\(anio))" }
        texto += texto.isEmpty ? fuente.titulo : ". \(fuente.titulo)"
        if let revista = fuente.revista { texto += ". \(revista)" }
        if let ubicacion { texto += ", \(ubicacion)" }
        return texto
    }
}
#endif

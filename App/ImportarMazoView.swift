// Importar un mazo desde Archivos. Solo en DEBUG: el formato es la propuesta del issue #6
// de la especificación y todavía puede cambiar.
#if DEBUG
import FichasDatos
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

extension View {
    /// Abre Archivos cuando `eligiendo` se activa, importa el mazo elegido y avisa qué pasó.
    /// Va en la pantalla y no en el botón de la barra: desde ahí el aviso no llega a mostrarse
    /// mientras se cierra el selector de archivos.
    func importarMazo(eligiendo: Binding<Bool>) -> some View {
        modifier(ImportarMazo(eligiendo: eligiendo))
    }
}

private struct ImportarMazo: ViewModifier {
    @Environment(\.modelContext) private var contexto
    @Binding var eligiendo: Bool
    @State private var aviso: Aviso?

    struct Aviso: Identifiable {
        let id = UUID()
        let titulo: String
        let mensaje: String
    }

    func body(content: Content) -> some View {
        content
            .fileImporter(isPresented: $eligiendo, allowedContentTypes: [.json]) { eleccion in
                if case .success(let url) = eleccion { importar(url) }
            }
            .alert(item: $aviso) { aviso in
                Alert(title: Text(aviso.titulo), message: Text(aviso.mensaje))
            }
    }

    private func importar(_ url: URL) {
        // Un archivo de iCloud o de otra app solo se puede leer mientras dure este permiso.
        let conPermiso = url.startAccessingSecurityScopedResource()
        defer { if conPermiso { url.stopAccessingSecurityScopedResource() } }
        do {
            let resultado = try ImportadorMazo.importar(Data(contentsOf: url), en: contexto)
            aviso = Aviso(titulo: "Mazo importado", mensaje: mensaje(de: resultado))
        } catch ErrorDatos.mazoInvalido(let detalle) {
            aviso = Aviso(titulo: "No se pudo importar", mensaje: detalle)
        } catch {
            aviso = Aviso(titulo: "No se pudo importar", mensaje: error.localizedDescription)
        }
    }

    /// Lo que ve el usuario después de importar.
    private func mensaje(de resultado: ResultadoImportacion) -> String {
        // Reimportar el mismo mazo da 0 nuevas: se dice que ya estaban para que no parezca un error.
        guard resultado.fichasNuevas > 0 else {
            return "Todas las fichas de este mazo ya estaban (\(contar(resultado.fichasRepetidas, "ficha", "fichas")))."
        }
        var partes = ["Se agregaron \(contar(resultado.fichasNuevas, "ficha nueva", "fichas nuevas"))"]
        if resultado.categoriasNuevas > 0 {
            partes.append("en \(contar(resultado.categoriasNuevas, "categoría nueva", "categorías nuevas"))")
        }
        var texto = partes.joined(separator: " ") + "."
        if resultado.fichasRepetidas > 0 {
            texto += " \(contar(resultado.fichasRepetidas, "ficha ya estaba y no se repitió", "fichas ya estaban y no se repitieron"))."
        }
        return texto
    }

    private func contar(_ n: Int, _ singular: String, _ plural: String) -> String {
        "\(n) \(n == 1 ? singular : plural)"
    }
}
#endif

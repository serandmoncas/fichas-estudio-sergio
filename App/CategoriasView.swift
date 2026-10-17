import FichasDatos
import SwiftData
import SwiftUI

/// Crear, renombrar y eliminar categorías (REQ-012).
struct CategoriasView: View {
    @Environment(\.modelContext) private var contexto
    @Query(sort: \Categoria.nombre) private var categorias: [Categoria]

    @State private var editando: EdicionNombre<Categoria>?
    @State private var bloqueada: Categoria?
    @State private var importando = false

    var body: some View {
        List {
            ForEach(categorias) { categoria in
                NavigationLink {
                    CategoriaView(categoria: categoria)
                } label: {
                    LabeledContent(categoria.nombre, value: "\(categoria.fichas.count)")
                }
                .contextMenu {
                    Button("Renombrar") { editando = .renombrar(categoria) }
                    Button("Eliminar", role: .destructive) { eliminar(categoria) }
                }
                .swipeActions {
                    Button("Eliminar", role: .destructive) { eliminar(categoria) }
                    Button("Renombrar") { editando = .renombrar(categoria) }
                }
            }
        }
        .overlay {
            if categorias.isEmpty {
                ContentUnavailableView("Sin categorías", systemImage: "folder",
                                       description: Text("Crea una categoría para empezar a agregar fichas."))
            }
        }
        .navigationTitle("Categorías")
        .toolbar {
            Button("Nueva categoría", systemImage: "plus") { editando = .nueva }
            #if DEBUG
            Button("Importar mazo", systemImage: "square.and.arrow.down") { importando = true }
            #endif
        }
        .pedirNombre($editando, titulo: "Categoría") { edicion, nombre in
            switch edicion {
            case .nueva: contexto.insert(Categoria(nombre: nombre))
            case .renombrar(let categoria): categoria.nombre = nombre
            }
        }
        #if DEBUG
        .importarMazo(eligiendo: $importando)
        #endif
        .alert("No se puede eliminar", isPresented: Binding(get: { bloqueada != nil }, set: { if !$0 { bloqueada = nil } }),
               presenting: bloqueada) { _ in
            Button("Entendido", role: .cancel) {}
        } message: { categoria in
            Text("“\(categoria.nombre)” todavía tiene \(categoria.fichas.count) fichas. Muévelas a otra categoría o bórralas primero.")
        }
    }

    private func eliminar(_ categoria: Categoria) {
        do {
            try contexto.eliminar(categoria)
        } catch ErrorDatos.categoriaConFichas {
            bloqueada = categoria
        } catch {
            assertionFailure("No se pudo eliminar la categoría: \(error)")
        }
    }
}

/// Algo que tiene un nombre que el usuario puede cambiar.
protocol ConNombre: AnyObject {
    var nombre: String { get set }
}

extension Categoria: ConNombre {}
extension Subcategoria: ConNombre {}

/// Qué nombre se está pidiendo: uno nuevo o el de un elemento existente.
enum EdicionNombre<Elemento: ConNombre>: Identifiable {
    case nueva
    case renombrar(Elemento)

    var id: String {
        switch self {
        case .nueva: "nueva"
        case .renombrar(let elemento): "renombrar-\(ObjectIdentifier(elemento))"
        }
    }

    var nombreActual: String {
        if case .renombrar(let elemento) = self { elemento.nombre } else { "" }
    }
}

extension View {
    /// Muestra un cuadro para escribir un nombre. Ignora nombres vacíos.
    func pedirNombre<Elemento: ConNombre>(
        _ edicion: Binding<EdicionNombre<Elemento>?>,
        titulo: String,
        guardar: @escaping (EdicionNombre<Elemento>, String) -> Void
    ) -> some View {
        modifier(PedirNombre(edicion: edicion, titulo: titulo, guardar: guardar))
    }
}

private struct PedirNombre<Elemento: ConNombre>: ViewModifier {
    @Binding var edicion: EdicionNombre<Elemento>?
    let titulo: String
    let guardar: (EdicionNombre<Elemento>, String) -> Void
    @State private var nombre = ""

    func body(content: Content) -> some View {
        content
            .alert(edicion.map { if case .nueva = $0 { "Nueva \(titulo.lowercased())" } else { "Renombrar" } } ?? titulo,
                   isPresented: Binding(get: { edicion != nil }, set: { if !$0 { edicion = nil } })) {
                TextField("Nombre", text: $nombre)
                Button("Cancelar", role: .cancel) {}
                Button("Guardar") {
                    let limpio = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let edicion, !limpio.isEmpty { guardar(edicion, limpio) }
                }
            }
            .onChange(of: edicion?.id) { nombre = edicion?.nombreActual ?? "" }
    }
}

#Preview {
    NavigationStack { CategoriasView() }
        .modelContainer(try! Almacen.contenedorEnMemoria())
}

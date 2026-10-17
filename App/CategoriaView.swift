import FichasDatos
import SwiftData
import SwiftUI

/// Una categoría: sus subcategorías (REQ-013) y cuántas fichas tiene.
struct CategoriaView: View {
    @Environment(\.modelContext) private var contexto
    let categoria: Categoria

    @State private var editando: EdicionNombre<Subcategoria>?

    private var subcategorias: [Subcategoria] {
        categoria.subcategorias.sorted { $0.nombre.localizedStandardCompare($1.nombre) == .orderedAscending }
    }

    var body: some View {
        List {
            Section("Subcategorías") {
                ForEach(subcategorias) { subcategoria in
                    LabeledContent(subcategoria.nombre, value: "\(subcategoria.fichas.count)")
                        .contextMenu {
                            Button("Renombrar") { editando = .renombrar(subcategoria) }
                            Button("Eliminar", role: .destructive) { contexto.delete(subcategoria) }
                        }
                        .swipeActions {
                            Button("Eliminar", role: .destructive) { contexto.delete(subcategoria) }
                            Button("Renombrar") { editando = .renombrar(subcategoria) }
                        }
                }
                Button("Agregar subcategoría", systemImage: "plus") { editando = .nueva }
            }
            Section {
                LabeledContent("Fichas", value: "\(categoria.fichas.count)")
            } footer: {
                // Al eliminar una subcategoría sus fichas no se pierden (ver EliminarCategoriaTests).
                Text("Si eliminas una subcategoría, sus fichas quedan en “\(categoria.nombre)”.")
            }
        }
        .navigationTitle(categoria.nombre)
        .pedirNombre($editando, titulo: "Subcategoría") { edicion, nombre in
            switch edicion {
            case .nueva: categoria.subcategorias.append(Subcategoria(nombre: nombre))
            case .renombrar(let subcategoria): subcategoria.nombre = nombre
            }
        }
    }
}

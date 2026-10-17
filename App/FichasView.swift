import FichasDatos
import SwiftData
import SwiftUI

/// Fichas de una categoría: listar, crear, editar y eliminar (REQ-010 a REQ-017).
struct FichasView: View {
    @Environment(\.modelContext) private var contexto
    let categoria: Categoria

    @State private var formulario: FichaFormView.Modo?

    private var fichas: [Ficha] {
        categoria.fichas.sorted { $0.pregunta.localizedStandardCompare($1.pregunta) == .orderedAscending }
    }

    var body: some View {
        List {
            ForEach(fichas) { ficha in
                Button {
                    formulario = .editar(ficha)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ficha.pregunta).foregroundStyle(.primary)
                        if let subcategoria = ficha.subcategoria {
                            Text(subcategoria.nombre).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .swipeActions {
                    Button("Eliminar", role: .destructive) { contexto.delete(ficha) }
                }
                .contextMenu {
                    Button("Eliminar", role: .destructive) { contexto.delete(ficha) }
                }
            }
        }
        .overlay {
            if fichas.isEmpty {
                ContentUnavailableView("Sin fichas", systemImage: "rectangle.on.rectangle",
                                       description: Text("Agrega la primera ficha de “\(categoria.nombre)”."))
            }
        }
        .navigationTitle("Fichas")
        .toolbar {
            Button("Nueva ficha", systemImage: "plus") { formulario = .nueva(categoria) }
        }
        .sheet(item: $formulario) { FichaFormView(modo: $0) }
    }
}

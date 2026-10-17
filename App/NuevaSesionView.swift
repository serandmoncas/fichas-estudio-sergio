import FichasCore
import FichasDatos
import SwiftData
import SwiftUI

/// Elegir categorías o subcategorías y cuántas fichas (REQ-021, REQ-022).
struct NuevaSesionView: View {
    @Environment(\.modelContext) private var contexto
    @Query(sort: \Categoria.nombre) private var categorias: [Categoria]
    @Query private var fichas: [Ficha]

    @State private var categoriasElegidas = Set<PersistentIdentifier>()
    @State private var subcategoriasElegidas = Set<PersistentIdentifier>()
    @State private var cantidad = 10
    @State private var enCurso: SesionEnCurso?

    /// Las fichas que entrarían, sin mezclar ni recortar; sirve para avisar si hay menos que las pedidas.
    private var disponibles: Int {
        fichas.filter { ficha in
            ficha.categoria.map { categoriasElegidas.contains($0.persistentModelID) } == true
                || ficha.subcategoria.map { subcategoriasElegidas.contains($0.persistentModelID) } == true
        }.count
    }

    var body: some View {
        Form {
            ForEach(categorias) { categoria in
                Section {
                    Toggle(categoria.nombre, isOn: elegida(categoria.persistentModelID, en: $categoriasElegidas))
                    ForEach(categoria.subcategorias.sorted { $0.nombre < $1.nombre }) { subcategoria in
                        Toggle(subcategoria.nombre, isOn: elegida(subcategoria.persistentModelID, en: $subcategoriasElegidas))
                            .padding(.leading)
                            // Si la categoría entera está elegida, sus subcategorías ya entran.
                            .disabled(categoriasElegidas.contains(categoria.persistentModelID))
                    }
                }
            }

            Section {
                Stepper("\(cantidad) fichas", value: $cantidad, in: 1...100)
            } footer: {
                if disponibles < cantidad && disponibles > 0 {
                    // Pregunta abierta 14: por ahora entran todas las que hay.
                    Text("Solo hay \(disponibles) fichas en lo que elegiste; la sesión tendrá \(disponibles).")
                }
            }

            Button("Empezar") { empezar() }
                .buttonStyle(.borderedProminent)
                .disabled(disponibles == 0)
        }
        .formStyle(.grouped)
        .overlay {
            if categorias.isEmpty {
                ContentUnavailableView("Sin categorías", systemImage: "folder",
                                       description: Text("Crea categorías y fichas antes de estudiar."))
            }
        }
        .navigationTitle("Nueva sesión")
        .navigationDestination(item: $enCurso) { EstudioView(enCurso: $0) }
    }

    private func elegida(_ id: PersistentIdentifier, en conjunto: Binding<Set<PersistentIdentifier>>) -> Binding<Bool> {
        Binding(
            get: { conjunto.wrappedValue.contains(id) },
            set: { if $0 { conjunto.wrappedValue.insert(id) } else { conjunto.wrappedValue.remove(id) } }
        )
    }

    private func empezar() {
        let candidatas = fichas.compactMap { ficha -> FichaCandidata<PersistentIdentifier>? in
            guard let categoria = ficha.categoria else { return nil }
            return FichaCandidata(id: ficha.persistentModelID, categoria: categoria.persistentModelID,
                                  subcategoria: ficha.subcategoria?.persistentModelID)
        }
        var generador = SystemRandomNumberGenerator()
        let ids = seleccionarFichasSesion(fichas: candidatas, categorias: categoriasElegidas,
                                          subcategorias: subcategoriasElegidas, cantidad: cantidad,
                                          generador: &generador)
        let porId = Dictionary(uniqueKeysWithValues: fichas.map { ($0.persistentModelID, $0) })

        let sesion = Sesion(
            inicio: .now,
            categorias: categorias.filter { categoriasElegidas.contains($0.persistentModelID) },
            subcategorias: categorias.flatMap(\.subcategorias).filter { subcategoriasElegidas.contains($0.persistentModelID) },
            fichasSolicitadas: cantidad
        )
        contexto.insert(sesion)
        enCurso = SesionEnCurso(sesion: sesion, fichas: ids.compactMap { porId[$0] })
    }
}

/// Una sesión que empezó y las fichas que le tocan, en orden.
struct SesionEnCurso: Hashable {
    let sesion: Sesion
    let fichas: [Ficha]
}

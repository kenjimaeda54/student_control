//
//  VerificationSheet.swift
//  control_student
//
//  Created by kenjimaeda on 18/04/26.
//

import SwiftUI
import PhotosUI

struct VerificationSheet: View {
    @ObservedObject var manager: StudentShieldManagerBlockNotAll
        @State private var isValidating = false
        
        // Estado para o seletor múltiplo
        @State private var selectedItems: [PhotosPickerItem] = []

        var body: some View {
            VStack(spacing: 24) {
                Capsule()
                    .frame(width: 40, height: 6)
                    .foregroundColor(.secondary.opacity(0.5))
                    .padding(.top, 12)

                Text("Validação em Tempo Real")
                    .font(.headline)

                VStack(spacing: 8) {
                    Text(timeString(manager.preLessonTimerRemaining))
                        .font(.system(size: 54, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                    
                    Text("O bloqueio já está ativo!")
                        .font(.subheadline.bold())
                        .foregroundColor(.red)
                }

                Text("Agora, saia do app e tire prints das suas telas para mostrar que os outros apps estão bloqueados. Depois, volte aqui e envie as fotos.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // MARK: - Seletor de Fotos Corrigido
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 5, // Permite selecionar vários prints
                    matching: .images
                ) {
                    Label(
                        selectedItems.isEmpty ? "Selecionar Prints de Prova" : "\(selectedItems.count) Prints selecionados",
                        systemImage: "photo.on.rectangle.angled"
                    )
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .onChange(of: selectedItems) { _ in
                    loadSelectedImages()
                }

                Spacer()

                // MARK: - Botão Iniciar Aula (Conectado ao Backend)
                Button {
                    Task {
                        isValidating = true
                        manager.startLesson = true
                    }
                } label: {
                    if isValidating {
                        ProgressView().tint(.white)
                    } else {
                        Text("Iniciar Aula")
                            .bold()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedItems.isEmpty ? Color.gray : Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(selectedItems.isEmpty || isValidating) // Só ativa se tiver fotos
                .padding(.horizontal)
                .padding(.bottom, 30)
                .sheet(isPresented: $manager.startLesson) {
//                    LessonStatusSheet(manager: manager)
//                        .interactiveDismissDisabled(true)
                }
            }
        }

        // Carrega os itens do PhotosPicker para a lista de UIImages no Manager
        private func loadSelectedImages() {
            Task {
                var loadedImages: [UIImage] = []
                for item in selectedItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        loadedImages.append(image)
                    }
                }
                await MainActor.run {
                    manager.verificationImages = loadedImages
                }
            }
        }

        func timeString(_ totalSeconds: Int) -> String {
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }
}

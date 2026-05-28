//
//  Student.swift
//  control_student
//
//  Created by kenjimaeda on 05/03/26.
//

// ManagerStudent.swift


// StudentScreen.swift

import SwiftUI
import FamilyControls

struct StudentScreen: View {
    @StateObject var manager = StudentState()
    @State private var isSending = false
    @State private var sendError = false
    @State private var isPickerPresented = false


    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Spacer()

                Image(systemName: "loc/Confirmark.shield.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .padding(.bottom, 24)

                Text("Modo Foco")
                    .font(.title).bold()
                    .padding(.bottom, 8)

                Text("Ao iniciar a aula, todos os apps e sites serão bloqueados.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer().frame(height: 32)

                VStack(spacing: 12) {
                    bloqueioItem(icon: "apps.iphone", text: "Todos os apps bloqueados")
                    bloqueioItem(icon: "safari", text: "Safari e navegadores bloqueados")
                    bloqueioItem(icon: "bell.slash", text: "Notificações impedidas de distrair")
                }
                .padding(.horizontal, 40)

                Spacer()

                actionFooter
            }
            .navigationTitle("Estudo")
            .sheet(isPresented: $manager.showLessonSheet) {
                LessonStatusSheet(manager: manager)
                    .interactiveDismissDisabled(true)
            }
        }
        .onAppear {
            Task { await manager.requestAccess() }
        }
    }

    private func bloqueioItem(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red.opacity(0.7))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func statusColor(_ status: StudentStatus) -> Color {
        switch status {
        case .pending: return .yellow
        case .failure: return .red
        case .ok: return .green
        }
    }

    private var actionFooter: some View {
        VStack(spacing: 12) {
            Divider()

            if sendError {
                Label("Erro ao iniciar. Tente novamente.", systemImage: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button {
                Task {
                    isSending = true
                    sendError = false
                    let success = await manager.startLessonWithoutScreenshot()
                    if success {
                        manager.showLessonSheet = true
                    } else {
                        sendError = true
                    }
                    isSending = false
                }
            } label: {
                HStack {
                    if isSending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, 4)
                    }
                    Text("Iniciar Aula")
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(isSending)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

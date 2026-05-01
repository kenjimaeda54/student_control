//
//  TeacherScreen.swift
//  control_student
//
//  Created by kenjimaeda on 05/03/26.
//

import SwiftUI
import FamilyControls

struct TeacherScreen: View {
    @StateObject private var manager = TeacherState()
    @State private var sessionDuration: Double = 45

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                studentStatusCard
                durationControl
                controlButtons
                Spacer()
            }
            .padding()
            .navigationTitle("Professor")
        }
    }


    var studentStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Status do Aluno")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(studentStatusLabel)
                        .bold()
                        .foregroundColor(studentStatusColor)

                    if manager.isLessonActive {
                        Text(formatTime(manager.timeRemaining))
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                }

                Spacer()

                Circle()
                    .fill(studentStatusColor)
                    .frame(width: 12)
            }

            if manager.exitRequested && !manager.canExit {
                Divider()

                HStack(spacing: 12) {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Aluno solicitou encerramento")
                            .font(.subheadline).bold()
                        Text("Libere para permitir que ele encerre a aula.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button {
                        grantExit()
                    } label: {
                        Text("Liberar")
                            .bold()
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(12)
    }

    // MARK: - Duration Control

    var durationControl: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Duração da Aula")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(sessionDuration)) min")
                    .font(.subheadline).bold()
            }

            Slider(value: $sessionDuration, in: 5...120, step: 5)
                .disabled(manager.isLessonActive)
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(12)
    }

    // MARK: - Control Buttons

    var controlButtons: some View {
        VStack(spacing: 12) {
            
            if !manager.codeStartClass.isEmpty {
                Label("Codigo para iniciar aula é \(manager.codeStartClass)", systemImage: "key.fill")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.12))
                    .foregroundColor(.orange)
                    .cornerRadius(12)
                    .transition(.opacity) // Suaviza a aparição
            } else {
                Button {
                    manager.startstartSession()
                } label: {
                    Label("Iniciar Aula", systemImage: "lock.fill")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }

            if manager.isLessonActive {

                // pausar / retomar bloqueio
                Button {
                    toggleLock()
                } label: {
                    Label(
                        manager.isLockedByProfessor ? "Retomar Bloqueio" : "Pausar Bloqueio",
                        systemImage: manager.isLockedByProfessor ? "lock.fill" : "lock.open"
                    )
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.12))
                    .foregroundColor(.orange)
                    .cornerRadius(12)
                }
            }

            // finalizar aula
            Button {
                cancelSession()
            } label: {
                Label("Finalizar Aula", systemImage: "xmark.circle.fill")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(manager.isLessonActive ? .red : .gray)
            }
            .disabled(!manager.isLessonActive)
        }
    }

    // MARK: - Helpers

    var canStart: Bool {
        manager.isSelectionValid && !manager.isLessonActive
    }

    var studentStatusLabel: String {
        if manager.canExit { return "SAÍDA LIBERADA" }
        if manager.exitRequested { return "SOLICITANDO SAÍDA" }
        if manager.isLessonActive { return "AULA EM ANDAMENTO" }
        if manager.isSelectionValid { return "ALUNO PRONTO" }
        return "AGUARDANDO ALUNO"
    }

    var studentStatusColor: Color {
        if manager.canExit { return .green }
        if manager.exitRequested { return .orange }
        if manager.isLessonActive { return .blue }
        if manager.isSelectionValid { return .green }
        return .orange
    }


    func cancelSession() {
//        // 🔌 quando backend estiver pronto, substituir por:
//        Task {
//            var request = URLRequest(url: URL(string: "https://seubackend.com/stop-lesson")!)
//            request.httpMethod = "POST"
//            let body = ["student_id": "ID_DO_ALUNO"]
//            request.httpBody = try? JSONEncoder().encode(body)
//            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            try? await URLSession.shared.data(for: request)
//        }

        // 🔌 remover simulação quando backend estiver pronto
        //manager.stopLesson()
    }

    func toggleLock() {
        manager.setTeacherLook(active: !manager.isLockedByProfessor)
    }

    func grantExit() {
//        // 🔌 quando backend estiver pronto, substituir por:
//        Task {
//            var request = URLRequest(url: URL(string: "https://seubackend.com/grant-exit")!)
//            request.httpMethod = "POST"
//            let body = ["student_id": "ID_DO_ALUNO"]
//            request.httpBody = try? JSONEncoder().encode(body)
//            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            try? await URLSession.shared.data(for: request)
//            // backend emite WebSocket pro aluno → canExit = true é setado lá
//        }

        // 🔌 remover simulação quando backend estiver pronto
        manager.canExit = true
    }

    func formatTime(_ s: Int) -> String {
        let m = s / 60
        let sec = s % 60
        return String(format: "%02d:%02d", m, sec)
    }
}

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
                durationControl
                controlButtons
                Spacer()
            }
            .padding()
            .navigationTitle("Professor")
        }
    }

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
                .onChange(of: sessionDuration) { newValue in
                    manager.timeRemaining = Int(newValue) * 60
                }
                .disabled(manager.isLessonActive)
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(12)
    }


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

            if !manager.students.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Alunos:")
                        .font(.headline)
                        .padding(.horizontal, 12)
                    
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(manager.students) { student in
                                HStack {
                                    Text(student.name)
                                        .font(.body)
                                    Spacer()
                                    Text(student.status.rawValue)
                                        .font(.caption).bold()
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(statusColor(student.status))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                    .frame(maxHeight: 200)
                }
                .padding(.top, 16)
            }
        }
    }

    // MARK: - Helpers

    private func statusColor(_ status: StudentStatus) -> Color {
        switch status {
        case .pending: return .yellow
        case .failure: return .red
        case .ok: return .green
        case .started: return  .green
        }
    }

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

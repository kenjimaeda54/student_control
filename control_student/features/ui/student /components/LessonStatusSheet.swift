//
//  LessonStatusSheet.swift
//  control_student
//
//  Created by kenjimaeda on 16/03/26.
//


import SwiftUI

struct LessonStatusSheet: View {
    @ObservedObject var manager: StudentState

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: statusIcon)
                .font(.system(size: 64))
                .foregroundColor(statusColor)

            // status principal
            VStack(spacing: 8) {
                Text(statusTitle)
                    .font(.title2).bold()
                Text(statusSubtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if manager.lessonStarted && manager.timeRemaining > 0 {
                Text(formatTime(manager.timeRemaining))
                    .font(.system(size: 52, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
            }

            Spacer()

            if manager.lessonStarted && !manager.exitRequested && !manager.canExit {
                Button {
                    Task { await manager.requestExit() }
                } label: {
                    Label("Solicitar Encerramento", systemImage: "hand.raised.fill")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.15))
                        .foregroundColor(.orange)
                        .cornerRadius(12)
                }
            }

            if manager.exitRequested && !manager.canExit {
                Label("Aguardando aprovação do professor...", systemImage: "clock.fill")
                    .foregroundColor(.orange)
                    .font(.subheadline)
            }

            Button {
                manager.stopLesson()
            } label: {
                Label("Encerrar Aula", systemImage: "xmark.circle.fill")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(manager.canExit ? Color.red.opacity(0.15) : Color.gray.opacity(0.1))
                    .foregroundColor(manager.canExit ? .red : .gray)
                    .cornerRadius(12)
            }
            .disabled(!manager.canExit)
        }
        .padding(24)
    }

    // MARK: - Helpers

    private var statusIcon: String {
        if manager.canExit { return "checkmark.circle.fill" }
        if manager.lessonStarted { return "lock.fill" }
        return "clock.fill"
    }

    private var statusColor: Color {
        if manager.canExit { return .green }
        if manager.lessonStarted { return .blue }
        return .orange
    }

    private var statusTitle: String {
        if manager.canExit { return "Você pode sair!" }
        if manager.lessonStarted { return "Aula em andamento" }
        return "Aguardando início"
    }

    private var statusSubtitle: String {
        if manager.canExit { return "O professor liberou seu encerramento." }
        if manager.lessonStarted { return "Seus apps estão bloqueados durante a aula." }
        return "O professor iniciará a aula em breve."
    }

    private func formatTime(_ s: Int) -> String {
        let m = s / 60
        let sec = s % 60
        return String(format: "%02d:%02d", m, sec)
    }
}

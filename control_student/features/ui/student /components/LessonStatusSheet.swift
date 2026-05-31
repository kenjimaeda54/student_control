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
        return "lock.fill"
    }

    private var statusColor: Color {
        if manager.canExit { return .green }
        return .blue
    }

    private var statusTitle: String {
        if manager.canExit { return "Você pode sair!" }
        return "Aula em andamento"
    }

    private var statusSubtitle: String {
        if manager.canExit { return "O professor liberou seu encerramento." }
        return "Seus apps estão bloqueados durante a aula."
    }

    private func formatTime(_ s: Int) -> String {
        let m = s / 60
        let sec = s % 60
        return String(format: "%02d:%02d", m, sec)
    }
}

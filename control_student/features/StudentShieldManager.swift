//
//  ManagerStudent.swift
//  control_student
//
//  Created by kenjimaeda on 05/03/26.
//


import Foundation
import FamilyControls
import ManagedSettings
import SwiftUI
internal import Combine

class StudentShieldManager: ObservableObject {
    
    static let shared = StudentShieldManager()
    
    private let store = ManagedSettingsStore()
    private var webSocketTask: URLSessionWebSocketTask?
    private var lessonTimerTask: Task<Void, Never>?
    
    @Published var selection = FamilyActivitySelection(includeEntireCategory: false) {
        didSet {
            hasConfirmedVisualList = false
        }
    }

    @Published var hasConfirmedVisualList = false
    @Published var isLockedByProfessor = false
    @Published var isLessonActive = false
    @Published var showLessonSheet = false
    @Published var canExit = false
    @Published var exitRequested = false
    @Published var timeRemaining: Int = 0
    @Published var lessonStarted = false
    
    var isReadyToConfirm: Bool {
        isTechnicalSelectionValid
    }
    
    var isTechnicalSelectionValid: Bool {
        let apps = selection.applicationTokens.count
        let noCategories = selection.categoryTokens.isEmpty
        return apps == 3 && noCategories
    }
    
    var isSelectionValid: Bool {
        isTechnicalSelectionValid && hasConfirmedVisualList
    }

    // MARK: - Backend

    func confirmSelectionApps(screenshot: UIImage) async -> Bool {
        guard let imageData = screenshot.jpegData(compressionQuality: 0.8) else {
            print("❌ Erro ao converter imagem")
            return false
        }

//        var request = URLRequest(url: URL(string: "https://seubackend.com/validate-apps")!)
//        request.httpMethod = "POST"
//
//        let boundary = UUID().uuidString
//        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//
//        var body = Data()
//        body.append("--\(boundary)\r\n".data(using: .utf8)!)
//        body.append("Content-Disposition: form-data; name=\"screenshot\"; filename=\"apps.jpg\"\r\n".data(using: .utf8)!)
//        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
//        body.append(imageData)
//        body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
//        body.append("Content-Disposition: form-data; name=\"student_id\"\r\n\r\n".data(using: .utf8)!)
//        body.append("ID_DO_ALUNO\r\n".data(using: .utf8)!)
//        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
//        request.httpBody = body
//
//        do {
//            let (_, response) = try await URLSession.shared.data(for: request)
//            if let httpResponse = response as? HTTPURLResponse,
//               httpResponse.statusCode == 200 {
//                DispatchQueue.main.async {
//                    self.hasConfirmedVisualList = true
//                }
//                return true
//            }
//            return false
//        } catch {
//            print("❌ Erro ao enviar: \(error)")
//            return false
//        }

        // 🔌 remover simulação quando backend estiver pronto
        await MainActor.run { self.hasConfirmedVisualList = true }
        return true
    }

    func requestExit() async {
//        var request = URLRequest(url: URL(string: "https://seubackend.com/request-exit")!)
//        request.httpMethod = "POST"
//        let body = ["student_id": "ID_DO_ALUNO"]
//        request.httpBody = try? JSONEncoder().encode(body)
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        try? await URLSession.shared.data(for: request)

        // 🔌 remover simulação quando backend estiver pronto
        print("📤 Solicitação de saída enviada ao backend")
        await MainActor.run { self.exitRequested = true }
    }

    // MARK: - WebSocket

    func connectWebSocket() {
//        let url = URL(string: "wss://seubackend.com/ws/student/ID_DO_ALUNO")!
//        webSocketTask = URLSession.shared.webSocketTask(with: url)
//        webSocketTask?.resume()
//        listenWebSocket()

        // 🔌 remover simulação quando backend estiver pronto
        print("🔌 WebSocket conectado (simulado)")
    }

    private func listenWebSocket() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                if case .string(let text) = message,
                   let data = text.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    self.handleWebSocketEvent(json)
                }
                self.listenWebSocket()
            case .failure(let error):
                print("❌ WebSocket erro: \(error)")
            }
        }
    }

    private func handleWebSocketEvent(_ json: [String: Any]) {
        DispatchQueue.main.async {
            // professor iniciou a aula → { "event": "lesson_started", "duration": 2700 }
            if let event = json["event"] as? String {
                switch event {
                case "lesson_started":
                    let duration = json["duration"] as? Int ?? 2700
                    self.startLesson(duration: duration)

                // professor liberou saída → { "event": "exit_granted" }
                case "exit_granted":
                    self.canExit = true
                    print("✅ Professor liberou saída")

                default:
                    break
                }
            }
        }
    }

    func disconnectWebSocket() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }

    // MARK: - Lesson

    func startLesson(duration: Int) {
        isLessonActive = true
        lessonStarted = true
        timeRemaining = duration
        isLockedByProfessor = false
        updateShieldState()
        startLessonTimer()
        print("🎓 Aula iniciada — \(duration)s")
    }

    private func startLessonTimer() {
        lessonTimerTask?.cancel()
        lessonTimerTask = Task {
            while timeRemaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run { self.timeRemaining -= 1 }
            }
            await MainActor.run { self.stopLesson() }
        }
    }

    func stopLesson() {
        isLessonActive = false
        lessonStarted = false
        isLockedByProfessor = false
        canExit = false
        exitRequested = false
        timeRemaining = 0
        showLessonSheet = false
        lessonTimerTask?.cancel()
        disconnectWebSocket()
        updateShieldState()
    }

    func setProfessorLock(active: Bool) {
        isLockedByProfessor = active
        updateShieldState()
    }

    func updateShieldState() {
        guard isLessonActive else {
            store.shield.applicationCategories = nil
            store.shield.applications = nil
            print("🔓 Shield desativado")
            return
        }

        if isLockedByProfessor {
            store.shield.applicationCategories = nil
            store.shield.applications = nil
            print("⏸ Apps liberados pelo professor")
        } else {
            store.shield.applicationCategories = .all()
            store.shield.applications = selection.applicationTokens
            print("🛡 Whitelist ativa")
        }
    }

    // MARK: - Persist

    @MainActor
    func requestAccess() async {
        try? await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    }
}

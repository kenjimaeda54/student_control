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

class StudentShieldManagerBlockedAll: ObservableObject {
    
    static let shared = StudentShieldManagerBlockedAll()
    
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
    var isTechnicalSelectionValid: Bool {
        let apps = selection.applicationTokens.count
        let noCategories = selection.categoryTokens.isEmpty
        return apps == 3 && noCategories
    }
    
    var isSelectionValid: Bool {
        isTechnicalSelectionValid && hasConfirmedVisualList
    }
    
    
    private func handleWebSocketEvent(_ json: [String: Any]) {
        DispatchQueue.main.async {
            guard let event = json["event"] as? String else { return }
            
            switch event {
            case "student_ready": // Aluno terminou de selecionar os apps
                self.hasConfirmedVisualList = true
                
            case "exit_requested": // Aluno apertou o botão "Pedir para sair"
                self.exitRequested = true
                
            case "lesson_started":
                let duration = json["duration"] as? Int ?? 2700
                self.startLesson(duration: duration)
                
            case "exit_granted":
                self.canExit = true
                
            default:
                break
            }
        }
    }
    
    func sendStartLesson(studentId: String, durationInSeconds: Int) async {
        // 1. Chamada de API para o seu backend
        // 2. O backend envia um Push/WebSocket para o aluno
        // 3. Opcionalmente, você já atualiza o estado local se o professor e aluno estiverem no mesmo device (para testes)
        await MainActor.run {
            self.startLesson(duration: durationInSeconds)
        }
    }

    func sendStopLesson(studentId: String) async {
        // 1. Chamada de API: POST /stop-lesson
        await MainActor.run {
            self.stopLesson()
        }
    }

    func sendGrantExit(studentId: String) async {
        // 1. Chamada de API: POST /grant-exit
        await MainActor.run {
            self.canExit = true
            self.exitRequested = false
        }
    }

    // MARK: - Backend

    func confirmSelectionApps(screenshot: UIImage) async -> Bool {
        guard let imageData = screenshot.jpegData(compressionQuality: 0.9) else {
            print("❌ Erro ao converter imagem")
            return false
        }

        // mas em disddpositivo físico use o IP da sua máquina)
        guard let url = URL(string: "http://192.168.100.10:8080/validate-apps") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"screenshot\"; filename=\"apps.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            
            if httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? String {
                    
                    await MainActor.run {
                        self.hasConfirmedVisualList = (status == "approved")
                    }
                    return status == "approved"
                }
                return false
            } else {
                print("⚠️ Erro do servidor: \(httpResponse.statusCode)")
                return false
            }
        } catch {
            print("❌ Erro ao enviar: \(error)")
            return false
        }
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

    // Apenas updateShieldState muda — todo o resto permanece igual

    func updateShieldState() {
        guard isLessonActive else {
            store.clearAllSettings()
            print("🔓 Shield desativado")
            return
        }

        if isLockedByProfessor {
            store.clearAllSettings()
            print("⏸ Apps liberados pelo professor")
        } else {
            // Bloqueia tudo — sem exceções
            store.shield.applicationCategories = .all()
            store.shield.webDomainCategories = .all()
            print("🛡 Bloqueio total ativo")
        }
    }
    
    func startLessonWithoutScreenshot() async -> Bool {
        try? await Task.sleep(nanoseconds: 500_000_000)
        await MainActor.run {
            self.hasConfirmedVisualList = true
            self.connectWebSocket()
            self.startLesson(duration: 2700)
        }
        return true
    }

    // MARK: - Persist

    @MainActor
    func requestAccess() async {
        try? await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    }
}

//
//  ManagerStudent.swift
//  control_student
//
//  Created by kenjimaeda on 05/03/26.
//



//import Foundation
//import FamilyControls
//import ManagedSettings
//import SwiftUI
//internal import Combine
//
//class StudentShieldManager: ObservableObject {
//    static let shared = StudentShieldManager()
//    let store = ManagedSettingsStore()
//    
//    @Published var selection = FamilyActivitySelection(includeEntireCategory: true)
//    @Published var hasConfirmedVisualList = false
//    @Published var isLockedByProfessor = false
//
//    @MainActor
//    func requestAccess() async {
//        try? await AuthorizationCenter.shared.requestAuthorization(for: .individual)
//    }
//
//    func activateShield() {
//        store.shield.applicationCategories = .specific(selection.categoryTokens)
//        store.shield.applications = selection.applicationTokens
//        print("🔒 Apps bloqueados!")
//    }
//
//    func deactivateShield() {
//        store.shield.applicationCategories = nil
//        store.shield.applications = nil
//        selection = FamilyActivitySelection()
//        hasConfirmedVisualList = false
//        print("🔓 Apps liberados!")
//    }
//    
//    func getSelectionSummary() -> [String: Any] {
//        return [
//            "categories_count": selection.categoryTokens.count,
//            "apps_count": selection.applicationTokens.count,
//            "status": "READY"
//        ]
//    }
//}




import Foundation
import FamilyControls
import ManagedSettings
import SwiftUI
internal import Combine
import DeviceActivity

extension DeviceActivityName {
    static let daily = Self("daily")
}

class StudentShieldManager: ObservableObject {
    
    static let shared = StudentShieldManager()
    
    private let store = ManagedSettingsStore()
    private let defaults = UserDefaults.standard
    
    @Published var selection = FamilyActivitySelection(includeEntireCategory: false) {
        didSet {
            saveSelection()
            hasConfirmedVisualList = false
        }
    }

    
    @Published var hasConfirmedVisualList = false
    @Published var isLockedByProfessor = false
    @Published var isLessonActive = false
    
    init() {
        loadSelection()
    }
    
    var isReadyToConfirm: Bool {
        return isTechnicalSelectionValid
    }
    
    var isTechnicalSelectionValid: Bool {
        let apps = selection.applicationTokens.count
        let noCategories = selection.categoryTokens.isEmpty
        
        return apps == 3 && noCategories
    }
    
    var isSelectionValid: Bool {
        isTechnicalSelectionValid && hasConfirmedVisualList
    }
    
    

    func confirmSelectionWithProfessor(screenshot: UIImage) async {
        
        guard let imageData = screenshot.jpegData(compressionQuality: 0.8) else {
            print("❌ Erro ao converter imagem")
            return
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
//        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
//        
//        // ✅ Dados extras junto com a imagem
//        body.append("--\(boundary)\r\n".data(using: .utf8)!)
//        body.append("Content-Disposition: form-data; name=\"student_id\"\r\n\r\n".data(using: .utf8)!)
//        body.append("ID_DO_ALUNO\r\n".data(using: .utf8)!) // ← substitua pelo ID real
//        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
//        
//        request.httpBody = body
        
        do {
//            let (data, response) = try await URLSession.shared.data(for: request)
//            
//            if let httpResponse = response as? HTTPURLResponse,
//               httpResponse.statusCode == 200 {
//                DispatchQueue.main.async {
//                    self.hasConfirmedVisualList = true
//                    print("✅ Enviado para o professor!")
//                }
//            }
        } catch {
            print("❌ Erro ao enviar: \(error)")
        }
    }
    
    func getFilter() -> DeviceActivityFilter {
        let now = Date()
        let start = Calendar.current.startOfDay(for: now)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        
        return DeviceActivityFilter(
            segment: .daily(during: DateInterval(start: start, end: end)),
            applications: selection.applicationTokens,
            categories: selection.categoryTokens
        )
    }
    
    func startLesson() {
        guard isSelectionValid else {
            print("❌ Seleção inválida")
            return
        }
        
        isLessonActive = true
        isLockedByProfessor = false
        
        updateShieldState()
    }
    
    func stopLesson() {
        isLessonActive = false
        isLockedByProfessor = false
        
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
    
    
    func getSelectionSummary() -> [String: Any] {
        [
            "apps_count": selection.applicationTokens.count,
            "valid": isSelectionValid,
            "active": isLessonActive
        ]
    }
    
    
    private func saveSelection() {
        if let encoded = try? JSONEncoder().encode(selection) {
            defaults.set(encoded, forKey: "mopi_selection")
        }
    }
    
    private func loadSelection() {
        guard let data = defaults.data(forKey: "mopi_selection"),
              let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return }
        
        selection = decoded
    }
    
    
    @MainActor
    func requestAccess() async {
        try? await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    }
}

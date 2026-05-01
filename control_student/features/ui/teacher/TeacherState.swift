//
//  TeacherState.swift
//  control_student
//
//  Created by kenjimaeda on 28/04/26.
//

import Swifter
import Foundation
internal import Combine
import UIKit
import Network

class TeacherState: NSObject, ObservableObject, NetServiceDelegate {
    let server = HttpServer()
    @Published var exitRequested = false
    private var connectedSessions = Set<WebSocketSession>()
    @Published var isLessonActive = false
    @Published var canExit = false
    @Published var codeStartClass: String = ""
    @Published var isServerRunning = false
    @Published var isLockedByProfessor = false
    @Published var timeRemaining: Int = 0
    @Published var codeGenerateForStartClass: String = ""
    @Published var hasConfirmedVisualList = false
    var isTechnicalSelectionValid: Bool {
        
        return true
    }
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private var currentInterfaceType: NWInterface.InterfaceType?
    private var netService: NetService?
    private let port: Int32 = 8080
    
    override init() {
        super.init()
        startMonitoringNetwork()
        setupBonjour()
        startServer()
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    
    var isSelectionValid: Bool {
        isTechnicalSelectionValid && hasConfirmedVisualList
    }
    
    func setTeacherLook(active: Bool) {
        isLockedByProfessor = active
        updateShieldState()
    }
    
    func updateShieldState() {
//        guard isLessonActive else {
//            store.clearAllSettings()
//            print("🔓 Shield desativado")
//            return
//        }
//
//        if isLockedByProfessor {
//            store.clearAllSettings()
//            print("⏸ Apps liberados pelo professor")
//        } else {
//            // Bloqueia tudo — sem exceções
//            store.shield.applicationCategories = .all()
//            store.shield.webDomainCategories = .all()
//            print("🛡 Bloqueio total ativo")
//        }
    }
    
    private func startMonitoringNetwork() {
            monitor.pathUpdateHandler = { [weak self] path in
                guard let self = self else { return }
                
                if path.status == .satisfied {
                    let newInterface = path.availableInterfaces.first?.type
                    
                    if self.currentInterfaceType != nil && self.currentInterfaceType != newInterface {
                        print("🔄 Mudança de rede detectada. Reiniciando Bonjour...")
                        self.restartBonjour()
                    }
                    
                    self.currentInterfaceType = newInterface
                } else {
                    print("⚠️ Sem conexão de rede.")
                    self.stopBonjour()
                }
            }
            monitor.start(queue: monitorQueue)
        }

        private func restartBonjour() {
            DispatchQueue.main.async {
                self.stopBonjour()
                self.setupBonjour()
            }
        }

        func stopBonjour() {
            netService?.stop()
            netService = nil
            isServerRunning = false
        }

    func setupBonjour() {
        netService = NetService(domain: "local.", type: "_mopiaula._tcp.", name: "ClassRoom", port: port)
        netService?.delegate = self
        netService?.publish()
    }

    // MARK: - NetServiceDelegate
    func netServiceDidPublish(_ sender: NetService) {
        DispatchQueue.main.async {
            self.isServerRunning = true
            print("✅ Servidor anunciado na rede local!")
        }
    }

    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print("❌ Erro ao anunciar serviço: \(errorDict)")
    }
    
    func generateRandomCode() -> String {
        let num1 = Int.random(in: 0...10)
        let num2 = Int.random(in: 0...10)
        let num3 = Int.random(in: 0...10)
        return "\(num1)\(num2)\(num3)"
    }

    func startstartSession() {
        let code = generateRandomCode()
        codeStartClass = code
        DispatchQueue.main.async {
                    for session in self.connectedSessions {
                        session.writeText(code)
                    }
        }
    }
    
   func startServer() {
       server["/wsStatus"] = websocket(
               connected: { [weak self] session in
                   self?.connectedSessions.insert(session)
                   session.writeText("")
               },
               disconnected: { [weak self] session in
                   self?.connectedSessions.remove(session)
               }
           )

    do {
        try server.start(8080)
        print("Servidor do Professor rodando...")
    } catch {
        print("Erro: \(error)")
    }
  }
}

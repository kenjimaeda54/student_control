//
//  ConnectionStorage.swift
//  control_student
//
//  Created by kenjimaeda on 01/05/26.
//


import Foundation

struct ConnectionLog: Codable {
    var lastConnected: Date?
    var lastDisconnected: Date?
}

class ConnectionStorage {
    
    private static let key = "connection_log"
    
    static func save(_ log: ConnectionLog) {
        if let encoded = try? JSONEncoder().encode(log) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    static func load() -> ConnectionLog {
        guard let data = UserDefaults.standard.data(forKey: key),
              let log = try? JSONDecoder().decode(ConnectionLog.self, from: data) else {
            return ConnectionLog()
        }
        return log
    }
    
    // ✅ Limpa após enviar
    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

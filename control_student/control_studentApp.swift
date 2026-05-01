//
//  control_studentApp.swift
//  control_student
//
//  Created by kenjimaeda on 05/03/26.
//

import SwiftUI

@main
struct control_studentApp: App {
    @State private var userRole: UserRole? = nil
    
    var body: some Scene {
        WindowGroup {
            Group {
                if let role = userRole {
                    switch role {
                    case .teacher:
                        TeacherScreen()
                    case .student:
                        StudentScreen()
                    }
                } else {
                    RoleSelectionScreen(onRoleSelected: { selectedRole in
                        userRole = selectedRole
                    })
                }
            }
        }
    }
}



enum UserRole {
    case teacher, student
}

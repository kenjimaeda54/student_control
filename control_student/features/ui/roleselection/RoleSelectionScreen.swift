//
//  RoleScreen.swift
//  control_student
//
//  Created by kenjimaeda on 14/03/26.
//

import Foundation
import SwiftUI


struct RoleSelectionScreen: View {
    var onRoleSelected: (UserRole) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 10) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 70))
                        .foregroundColor(.blue)
                    Text("Bem-vindo")
                        .font(.largeTitle).bold()
                    Text("Escolha seu perfil para continuar")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 50)
                
                VStack(spacing: 20) {
                    RoleButton(title: "Sou Professor", icon: "person.badge.key.fill", color: .orange) {
                        onRoleSelected(.teacher)
                    }
                    
                    RoleButton(title: "Sou Aluno", icon: "book.fill", color: .blue) {
                        onRoleSelected(.student)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}

struct RoleButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.headline)
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
            }
            .padding()
            .frame(height: 80)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(20)
            .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
}

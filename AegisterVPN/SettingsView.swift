//
//  SettingsView.swift
//  AegisterVPN
//
//  Created by Aly Salman on 12/09/24.
//

import SwiftUI

struct SettingsView: View {
    @State private var errorMessage: String?
    @State private var showDeleteConfirmation = false
    
    @ObservedObject var vpnManager: VPNManager
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Image("Logo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 65, height: 65)
                    .padding(.bottom, 75)
                                
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Text("Logout")
                            .foregroundStyle(Color.red)
                            .frame(width: 175, height: 50)
                            .font(Font.custom("Archivo", size: 23, relativeTo: .headline ))
                            .bold()
                            .background(Color.accentColor)
                            .cornerRadius(12)
                }
                Spacer()
            }
            .BackgroundViewLogo(logo: Image("Aegister")) 
            .onChange(of: vpnManager.isConfigured) { oldValue, newValue in
                if oldValue != newValue {
                    if !newValue {
                        errorMessage = "Failed to configure VPN"
                    } else {
                        errorMessage = nil
                    }
                }
            }
            .onChange(of: vpnManager.isLoading) {
                if !vpnManager.isLoading {
                    errorMessage = nil
                }
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Log Out"),
                    message: Text("Are you sure you want to log out and delete the VPN configuration? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        vpnManager.disconnect()
                        vpnManager.deleteVPNConfiguration()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            vpnManager.checkVPNConfiguration()
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        
    }


}


#Preview {
    SettingsView(vpnManager: VPNManager())
}

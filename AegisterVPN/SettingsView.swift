//
//  SettingsView.swift
//  AegisterVPN
//
//  Created by Aly Salman on 12/09/24.
//

import SwiftUI

struct SettingsView: View {
    @State private var activationKey = ""
    @State private var errorMessage: String?
    @State private var showDeleteConfirmation = false
    
    @ObservedObject var vpnManager: VPNManager
    
    var body: some View {
        NavigationStack {
            VStack {
                Image("Logo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 55, height: 55)
                    .padding(.bottom, 50)

                if !vpnManager.isConfigured {
                    TextField("Enter Activation Key", text: $activationKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(.bottom, 5)
                    }

                    Button(action: {
                        fetchOVPNFile()
                    }) {
                        Text("Activate")
                            .foregroundStyle(Color.white)
                            .bold()
                            .padding()
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    .disabled(activationKey.isEmpty || vpnManager.isLoading)
                    .padding(.bottom, 20)

                    Text("VPN is not Activated")
                        .font(.headline)
                        .foregroundColor(.gray)
                } else {
                    Text("VPN is Activated")
                        .font(.headline)
                        .foregroundColor(.green)
                        .padding(.bottom, 20)
                    
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Text("Delete current VPN Configuration")
                            .foregroundStyle(Color.red)
                            .font(.footnote)
                            .bold()
                            .padding()
                    }
                }
            }
            .backgroundLogo(logo: Image("Aegister"))
            .padding()
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
                    title: Text("Delete VPN Configuration"),
                    message: Text("Are you sure you want to delete the VPN configuration? This action cannot be undone."),
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
    
    func fetchOVPNFile() {
        guard !activationKey.isEmpty else {
            errorMessage = "Activation key cannot be empty."
            return
        }

        errorMessage = nil
        vpnManager.fetchOVPNFile(with: activationKey)
    }
}
#Preview {
    SettingsView(vpnManager: VPNManager())
}

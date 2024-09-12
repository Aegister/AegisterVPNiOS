//
//  ActivationView.swift
//  AegisterVPN
//
//  Created by Aly Salman on 11/09/24.
//

import SwiftUI

struct ActivationView: View {
    @State private var activationKey = ""
    @State private var errorMessage: String?
    @State private var isActivated = false
    
    @ObservedObject var vpnManager: VPNManager
    
    var body: some View {
        NavigationStack {
            VStack {
                
                Image("Aegister")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 55, height: 55)
                    .padding(.bottom, 50)

                TextField("Enter Activation Key", text: $activationKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
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
                
                if vpnManager.isLoading {
                    ProgressView()
                }
            }
            .padding()
            .navigationDestination(isPresented: $isActivated) {
                ContentView()
            }
            .onChange(of: vpnManager.isConfigured) {
                if vpnManager.isConfigured {
                    isActivated = true
                } else {
                    errorMessage = "Failed to configure VPN"
                }
            }
            .onChange(of: vpnManager.isLoading) {
                if !vpnManager.isLoading {
                    errorMessage = nil
                }
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
        
        isActivated = false
    }
}

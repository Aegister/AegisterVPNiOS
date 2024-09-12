//
//  AegisterVPNApp.swift
//  AegisterVPN
//
//  Created by Aly Salman on 02/09/24.
//

import SwiftUI

@main
struct AegisterVPNApp: App {
    @StateObject private var vpnManager = VPNManager()
    @State private var isLoading = true

    var body: some Scene {
        WindowGroup {
            if isLoading {
                ProgressView()
                    .onAppear {
                        DispatchQueue.main.async {
                            vpnManager.checkVPNConfiguration()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                isLoading = false
                            }
                        }
                    }
            } else {
                if vpnManager.isConfigured {
                    ContentView()
                        .scrollDismissesKeyboard(.immediately)
                        .scrollIndicators(.never)
                } else {
                    ActivationView(vpnManager: vpnManager)
                        .scrollDismissesKeyboard(.immediately)
                        .scrollIndicators(.never)

                }
            }
        }
    }
}

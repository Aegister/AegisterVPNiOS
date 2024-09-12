//
//  ContentView.swift
//  AegisterVPN
//
//  Created by Aly Salman on 02/09/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var vpnManager = VPNManager()
    @State private var selection = 1
    var body: some View {
        TabView(selection:$selection) {
            ConnectScreen()
                .tabItem {
                    Image(systemName: "app.connected.to.app.below.fill")
                    Text("Connect")
                        .foregroundStyle(Color.accentColor)
                }
                .tag(1)
            SettingsView(vpnManager: vpnManager)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                        Text("Settings")
                        .foregroundStyle(Color.accentColor)
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
}

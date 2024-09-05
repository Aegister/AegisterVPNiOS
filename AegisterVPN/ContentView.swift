//
//  ContentView.swift
//  AegisterVPN
//
//  Created by Aly Salman on 02/09/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var vpnManager = VPNManager()

    var body: some View {
        VStack {
            Text(vpnManager.isConnected ? "Connected" : "Disconnected")
                .font(.largeTitle)
                .padding()

            Button(action: {
                if vpnManager.isConnected {
                    vpnManager.disconnect()
                } else {
                    vpnManager.connect()
                }
            }) {
                Text(vpnManager.isConnected ? "Disconnect" : "Connect")
                    .font(.title)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

//
//  ConnectScreen.swift
//  AegisterVPN
//
//  Created by Aly Salman on 12/09/24.
//

import SwiftUI

struct ConnectScreen: View {
    @StateObject private var vpnManager = VPNManager()

    var body: some View {
        VStack {
            HStack {
                Image("Logo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 75, height: 75)
            }
            .padding(.trailing, 225)
            .padding(.top)
            Spacer()
            VStack {
                Image("Aegister")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 55, height: 55)
                    .padding(.bottom, 50)

                Toggle("Connect", isOn: $vpnManager.isConnected)
                    .toggleStyle(.switch)
                    .tint(.accentColor)
                    .labelsHidden()
                    .fixedSize()
                    .scaleEffect(CGSize(width: 3.3, height: 2.5))
                    .onChange(of: vpnManager.isConnected) {
                        if vpnManager.isConnected {
                            vpnManager.connect()
                        } else {
                            vpnManager.disconnect()
                        }
                    }
                    .padding(.bottom)

                Text(vpnManager.statusMessage)
                    .font(.title2)
                    .padding(.top, 25)
                    .foregroundColor(vpnManager.isConnected ? .white : .red)
            }
            Spacer()
        }
    }
}

#Preview {
    ConnectScreen()
}

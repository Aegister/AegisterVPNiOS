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
            Spacer()
            
            Image("Logo")
                .resizable()
                .scaledToFill()
                .frame(width: 55, height: 55)
                .padding(.bottom, 50)

                    
            Button(action: {
                if vpnManager.isConnected {
                    vpnManager.disconnect()
                } else {
                    vpnManager.connect()
                }
            }) {
                Text(vpnManager.statusMessage)
                    .bold()
                    .padding()
                    .frame(maxWidth: 235)
                    .background( Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
                        
            Spacer()
        }
        .backgroundLogo(logo: Image("Aegister"))
    }
}

#Preview {
    ConnectScreen()
}

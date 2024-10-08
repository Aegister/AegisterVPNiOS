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
            
            Spacer()
            
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
                    .frame(maxWidth: .infinity)
                    .background( Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 50)
            .padding(.bottom)
                        
            Spacer()
        }
        .backgroundLogo(logo: Image("Aegister"))
    }
}

#Preview {
    ConnectScreen()
}

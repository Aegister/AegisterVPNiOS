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
                .frame(width: 65, height: 65)
                .padding(.bottom, 75)
                    
            Button(action: {
                if vpnManager.isConnected {
                    vpnManager.disconnect()
                } else {
                    vpnManager.connect()
                }
            }) {
                Text(vpnManager.statusMessage)
                    .bold()
                    .font(Font.custom("Archivo", size: 23, relativeTo: .headline ))
                    .frame(width: 175, height: 50)
                    .background( Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
                        
            Spacer()
        }
        .BackgroundViewLogo(logo: Image("Aegister"))
    }
}

#Preview {
    ConnectScreen()
}

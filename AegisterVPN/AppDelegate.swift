//
//  AppDelegate.swift
//  AegisterVPN
//
//  Created by Aly Salman on 02/09/24.
//

import NetworkExtension
import SwiftUI

class VPNManager: ObservableObject {
    @Published var isConnected = false
    private var providerManager: NETunnelProviderManager?

    init() {
        loadOrCreateVPNProfile()
    }

    private func loadOrCreateVPNProfile() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] (managers, error) in
            guard error == nil else {
                return
            }

            self?.providerManager = managers?.first ?? NETunnelProviderManager()
            self?.configureVPNProfile()
        }
    }

    private func configureVPNProfile() {
        providerManager?.loadFromPreferences { [weak self] error in
            guard error == nil else {
                return
            }

            let tunnelProtocol = NETunnelProviderProtocol()

            guard
                let configurationFileURL = Bundle.main.url(forResource: "App", withExtension: "ovpn"),
                let configurationFileContent = try? Data(contentsOf: configurationFileURL)
            else {
                fatalError("Configuration file not found.")
            }

            tunnelProtocol.providerBundleIdentifier = "vpn.test.AegisterVPN.networkTarget"
            tunnelProtocol.providerConfiguration = ["ovpn": configurationFileContent]
            tunnelProtocol.serverAddress = ""

            self?.providerManager?.protocolConfiguration = tunnelProtocol
            self?.providerManager?.localizedDescription = "Aegister VPN"
            self?.providerManager?.isEnabled = true

            self?.providerManager?.saveToPreferences { error in
                if let error = error {
                    print(error)
                }
            }
        }
    }

    func connect() {
        providerManager?.loadFromPreferences { [weak self] error in
            guard error == nil else {
                print("Error loading preferences: \(String(describing: error))")
                return
            }

            do {
                try self?.providerManager?.connection.startVPNTunnel()
                self?.isConnected = true
            } catch {
                print("Error starting VPN tunnel: \(error)")
            }
        }
    }

    func disconnect() {
        providerManager?.connection.stopVPNTunnel()
        isConnected = false
    }
}

//
//  AppDelegate.swift
//  AegisterVPN
//
//  Created by Aly Salman on 02/09/24.
//

import NetworkExtension
import SwiftUI
import CoreData

//CoreData
class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }

    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

//VPN MANAGER CLASS
class VPNManager: ObservableObject {
    @Published var isConnected = false
    @Published var isConfigured = false
    @Published var isLoading = false
    @Published var statusMessage = "Connect"
    @Published var connectionStatus: NEVPNStatus = .disconnected

    private var providerManager: NETunnelProviderManager?
    private let context = PersistenceController.shared.container.viewContext

    init() {
        loadOrCreateVPNProfile()
        checkVPNConfiguration()
        monitorVPNStatus()
    }

    private func loadOrCreateVPNProfile() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] (managers, error) in
            guard error == nil else {
                print("Error loading from preferences: \(error!.localizedDescription)")
                return
            }

            self?.providerManager = managers?.first ?? NETunnelProviderManager()
        }
    }

    private func saveVPNConfiguration(data: Data) {
        let newProfile = VPNProfile(context: context)
        newProfile.id = UUID()
        newProfile.configurationData = data
        do {
            try context.save()
        } catch {
            print("Failed to save VPN configuration: \(error.localizedDescription)")
        }
    }

    private func loadVPNConfiguration() -> Data? {
        let fetchRequest: NSFetchRequest<VPNProfile> = VPNProfile.fetchRequest()
        do {
            let profiles = try context.fetch(fetchRequest)
            return profiles.first?.configurationData
        } catch {
            print("Failed to fetch VPN configuration: \(error.localizedDescription)")
            return nil
        }
    }

    func checkVPNConfiguration() {
        if let _ = loadVPNConfiguration() {
            DispatchQueue.main.async {
                self.isConfigured = true
            }
        } else {
            DispatchQueue.main.async {
                self.isConfigured = false
            }
        }
    }

    func fetchOVPNFile(with activationKey: String) {
        let urlString = "https://app.onefirewall.com/api/v1/vpn/cert/\(activationKey)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            DispatchQueue.main.async {
                self.isConfigured = false
            }
            return
        }

        let request = URLRequest(url: url)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Failed to fetch OVPN file: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.isConfigured = false
                }
                return
            }

            guard let data = data else {
                print("No data received from server.")
                DispatchQueue.main.async {
                    self?.isConfigured = false
                }
                return
            }

            if data.isEmpty {
                print("Fetched OVPN file data is empty.")
                DispatchQueue.main.async {
                    self?.isConfigured = false
                }
                return
            }

            self?.saveVPNConfiguration(data: data)
            self?.configureVPNProfile(with: data)
        }.resume()
    }

    private func configureVPNProfile(with ovpnFileData: Data) {
        providerManager?.loadFromPreferences { [weak self] error in
            guard error == nil else {
                print("Error loading preferences: \(String(describing: error))")
                DispatchQueue.main.async {
                    self?.isConfigured = false
                }
                return
            }

            guard !ovpnFileData.isEmpty else {
                print("Error: OVPN file data is empty.")
                DispatchQueue.main.async {
                    self?.isConfigured = false
                }
                return
            }

            let tunnelProtocol = NETunnelProviderProtocol()
            tunnelProtocol.providerBundleIdentifier = "com.Aegister.VPN.AegisterVPN.networkTarget"
            tunnelProtocol.providerConfiguration = ["ovpn": ovpnFileData]
            tunnelProtocol.serverAddress = ""

            self?.providerManager?.protocolConfiguration = tunnelProtocol
            self?.providerManager?.localizedDescription = "Aegister VPN"
            self?.providerManager?.isEnabled = true

            self?.providerManager?.saveToPreferences { error in
                if let error = error {
                    print("Error saving preferences: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self?.isConfigured = false
                    }
                } else {
                    print("VPN configuration saved successfully.")
                    DispatchQueue.main.async {
                        self?.isConfigured = true
                    }
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
                print("VPN tunnel started successfully.")
            } catch {
                print("Error starting VPN tunnel: \(error)")
            }
        }
    }
    private func monitorVPNStatus() {
        NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: nil,
            queue: OperationQueue.main) { [weak self] notification in
                self?.updateVPNStatus()
            }
    }

    private func updateVPNStatus() {
        guard let status = providerManager?.connection.status else { return }
        
        DispatchQueue.main.async {
            self.connectionStatus = status
            switch status {
            case .connected:
                self.isConnected = true
                self.statusMessage = "Connected"
            case .disconnected:
                self.isConnected = false
                self.statusMessage = "Disconnected"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.39) {
                    self.statusMessage = "Connect"
                }

            case .connecting:
                self.statusMessage = "Connecting..."
            case .disconnecting:
                self.statusMessage = "Disconnecting..."
    
            default:
                self.statusMessage = "Unknown status, make sure your VPN is activated"
            }
        }
    }
    func deleteVPNConfiguration() {
        providerManager?.removeFromPreferences { [weak self] error in
            if let error = error {
                print("Failed to remove VPN configuration: \(error.localizedDescription)")
                return
            }

            DispatchQueue.main.async {
                self?.isConnected = false
                print("VPN configuration removed successfully.")
            }
        }

        let fetchRequest: NSFetchRequest<VPNProfile> = VPNProfile.fetchRequest()
        do {
            let profiles = try context.fetch(fetchRequest)
            for profile in profiles {
                context.delete(profile)
            }
            try context.save()
            print("VPN configuration deleted from Core Data.")
        } catch {
            print("Failed to delete VPN configuration from Core Data: \(error.localizedDescription)")
        }
    }


    func disconnect() {
        providerManager?.connection.stopVPNTunnel()
        isConnected = false
        print("VPN tunnel stopped.")
    }
}

struct BackgroundLogoView: ViewModifier {
    var logoImage: Image
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    logoImage
                        .resizable()
                        .scaledToFit()
                        .opacity(0.5)
                        .offset(x: 175, y:0)
                        .blur(radius: 10)
                        .edgesIgnoringSafeArea(.all)
                }
            )
    }
}

extension View {
    func backgroundLogo(logo: Image) -> some View {
        self.modifier(BackgroundLogoView(logoImage: logo))
    }
}

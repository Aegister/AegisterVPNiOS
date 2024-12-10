//
//  AppDelegate.swift
//  AegisterVPN
//
//  Created by Aly Salman on 02/09/24.
//

import NetworkExtension
import SwiftUI
import CoreData
import UIKit
import Foundation


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
    
    func sendEmailToApi(token: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let urlString = "https://app.aegister.com/api/v1/vpn?include_cert=true&only_mine=true"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "X-Aegister-Token")
        

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching VPN profiles: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to fetch VPN profiles: Invalid response")
                DispatchQueue.main.async {
                    let fetchError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("fetchVpnFailed", comment: "Failed to fetch VPN profiles.")])
                    completion(.failure(fetchError))
                }
                return
            }

            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    let noDataError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("fetchVpnFailed", comment: "Failed to fetch VPN profiles.")])
                    completion(.failure(noDataError))
                }
                return
            }

            do {
                if let responseData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let error = responseData["error"] as? Int,
                   error == 0,
                   let vpnData = (responseData["data"] as? [[String: Any]])?.first,
                   let vpnCertContent = vpnData["cert"] as? String {
                    
                    if let certFileURL = self.saveCertToFile(certContent: vpnCertContent) {
                        do {
                            let certData = try Data(contentsOf: certFileURL)
                            DispatchQueue.main.async {
                                
                                self.saveVPNConfiguration(data: certData)
                                self.configureVPNProfile(with: certData)
                                completion(.success(()))
                            }
                        } catch {
                            print("Failed to load certificate data from file: \(error.localizedDescription)")
                            DispatchQueue.main.async {
                                completion(.failure(error))
                            }
                        }
                    } else {
                        print("Failed to save certificate file.")
                        DispatchQueue.main.async {
                            let saveError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Failed to save certificate file."])
                            completion(.failure(saveError))
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        print(NSLocalizedString("noVpnProfiles", comment: "No VPN profiles found for this email."))
                        let noProfilesError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("noVpnProfiles", comment: "No VPN profiles found for this email.")])
                        completion(.failure(noProfilesError))
                    }
                }
            } catch {
                print("Error parsing response data: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }

    func saveCertToFile(certContent: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to access documents directory.")
            return nil
        }
        
        // Define the file path and name
        let fileURL = documentsDirectory.appendingPathComponent("file.ovpn")
        
        // Write the certificate content directly to the file
        do {
            try certContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Certificate saved successfully at \(fileURL.path)")
            return fileURL
        } catch {
            print("Error saving certificate: \(error.localizedDescription)")
            return nil
        }
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
        guard let providerManager = self.providerManager else {
            print("Error: providerManager is nil.")
            DispatchQueue.main.async {
                self.isConfigured = false
            }
            return
        }

        print("Loading preferences...")
        providerManager.loadFromPreferences { [weak self] error in
            if let error = error {
                print("Error loading preferences: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.isConfigured = false
                }
                return
            }
            print("Preferences loaded successfully.")


            print("OVPN file data length: \(ovpnFileData.count)")
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
            print("Configuring tunnel protocol: \(tunnelProtocol)")

            providerManager.protocolConfiguration = tunnelProtocol
            providerManager.localizedDescription = "Aegister VPN"
            providerManager.isEnabled = true

            print("Saving VPN configuration to preferences...")
            providerManager.saveToPreferences { error in
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.39) {
                    self.statusMessage = "Disconnect"
                }
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


struct BackgroundView: ViewModifier {
    var logoImage: Image
    
    func body(content: Content) -> some View {
        ZStack {
            logoImage
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            content
        }
    }
}

extension View {
    func BackgroundViewLogo(logo: Image) -> some View {
        self.modifier(BackgroundView(logoImage: logo))
    }
}

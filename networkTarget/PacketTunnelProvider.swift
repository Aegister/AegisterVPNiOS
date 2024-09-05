//
//  PacketTunnelProvider.swift
//  networkTarget
//
//  Created by Aly Salman on 02/09/24.
//

import NetworkExtension
import OpenVPNAdapter

extension NEPacketTunnelFlow: OpenVPNAdapterPacketFlow {}

class PacketTunnelProvider: NEPacketTunnelProvider {

    lazy var vpnAdapter: OpenVPNAdapter = {
        let adapter = OpenVPNAdapter()
        adapter.delegate = self
        return adapter
    }()

    let vpnReachability = OpenVPNReachability()

    var startHandler: ((Error?) -> Void)?
    var stopHandler: (() -> Void)?

    override func startTunnel(
        options: [String : NSObject]?,
        completionHandler: @escaping (Error?) -> Void
    ) {
        guard
            let protocolConfiguration = protocolConfiguration as? NETunnelProviderProtocol,
            let providerConfiguration = protocolConfiguration.providerConfiguration
        else {
            fatalError("No protocol configuration available.")
        }

        guard let ovpnFileContent: Data = providerConfiguration["ovpn"] as? Data else {
            fatalError("No OpenVPN configuration found.")
        }

        let configuration = OpenVPNConfiguration()
        configuration.fileContent = ovpnFileContent

        do {
            try vpnAdapter.apply(configuration: configuration)
            print("Configuration applied successfully.")
            
            vpnReachability.startTracking { [weak self] status in
                guard status == .reachableViaWiFi else { return }
                self?.vpnAdapter.reconnect(afterTimeInterval: 5)
            }
            
            startHandler = completionHandler
            vpnAdapter.connect(using: packetFlow)
        } catch {
            print("Failed to apply configuration: \(error)")
            completionHandler(error)
        }
    }

    override func stopTunnel(
        with reason: NEProviderStopReason,
        completionHandler: @escaping () -> Void
    ) {
        stopHandler = completionHandler

        if vpnReachability.isTracking {
            vpnReachability.stopTracking()
        }

        vpnAdapter.disconnect()
    }
}

extension PacketTunnelProvider: OpenVPNAdapterDelegate {
    func openVPNAdapter(
        _ openVPNAdapter: OpenVPNAdapter,
        configureTunnelWithNetworkSettings networkSettings: NEPacketTunnelNetworkSettings?,
        completionHandler: @escaping (Error?) -> Void
    ) {
            networkSettings?.dnsSettings = NEDNSSettings(servers: ["208.67.222.222", "208.67.220.220"])
            networkSettings?.dnsSettings?.matchDomains = [""]
            
        setTunnelNetworkSettings(networkSettings, completionHandler: completionHandler)
    }
    
    func openVPNAdapter(
        _ openVPNAdapter: OpenVPNAdapter,
        handleEvent event: OpenVPNAdapterEvent, message: String?
    ) {
        switch event {
        case .connected:
            if reasserting {
                reasserting = false
            }

            startHandler?(nil)
            startHandler = nil

        case .disconnected:
            stopHandler?()
            stopHandler = nil

        case .reconnecting:
            reasserting = true

        default:
            break
        }
    }

    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleError error: Error) {
        guard let fatal = (error as NSError).userInfo[OpenVPNAdapterErrorFatalKey] as? Bool, fatal == true else { return }

        if vpnReachability.isTracking {
            vpnReachability.stopTracking()
        }

        if let startHandler = startHandler {
            startHandler(error)
            self.startHandler = nil
        } else {
            cancelTunnelWithError(error)
        }
    }

    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleLogMessage logMessage: String) {
    }
}

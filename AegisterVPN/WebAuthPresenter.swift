//
//  WebAuthPresenter.swift
//  AegisterVPN
//
//  Created by Aly Salman on 13/11/24.
//

import SwiftUI
import AuthenticationServices

struct WebAuthPresenter: UIViewControllerRepresentable {
    
    class Coordinator: NSObject, ASWebAuthenticationPresentationContextProviding {
        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            return ASPresentationAnchor()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        return viewController
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let url = URL(string: "https://app.aegister.com/keycloak/realms/aegister/protocol/openid-connect/auth?client_id=AegisterVPN&response_type=code&scope=openid%20email&redirect_uri=aegistervpn://auth/callback") {
            let authSession = ASWebAuthenticationSession(url: url, callbackURLScheme: "aegistervpn") { callbackURL, error in
                if let error = error {
                    print("Error during authentication session: \(error.localizedDescription)")
                } else if let callbackURL = callbackURL {
                    print("Authentication successful, callback URL: \(callbackURL)")

                    // Extract the authorization code
                    if let queryItems = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems,
                       let code = queryItems.first(where: { $0.name == "code" })?.value {
                        // Now you can safely call getKeycloakToken with the 'code' parameter
                        self.getKeycloakToken(with: code)
                    }
                }
            }
            authSession.presentationContextProvider = context.coordinator
            authSession.start()
        }
    }

    func getKeycloakToken(with code: String) {
        let tokenEndpoint = "https://app.aegister.com/keycloak/realms/aegister/protocol/openid-connect/token"
        let clientID = "AegisterVPN"
        let redirectURI = "aegistervpn://auth/callback"
        
        var request = URLRequest(url: URL(string: tokenEndpoint)!)
        request.httpMethod = "POST"
        let body = "grant_type=authorization_code&client_id=\(clientID)&code=\(code)&redirect_uri=\(redirectURI)&scope=openid&response_type=code"
        request.httpBody = body.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else { return }
            
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let accessToken = json["access_token"] as? String {
                print("Access token: \(accessToken)")
                VPNManager().sendEmailToApi(token: accessToken) { result in
                    switch result {
                    case .success:
                        print("API call made successfully.")
                    case .failure(let error):
                        print("Failed to activate VPN: \(error.localizedDescription)")
                    }
                }
            }
        }.resume()
    }
    
}





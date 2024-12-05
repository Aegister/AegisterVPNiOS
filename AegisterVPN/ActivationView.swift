//
//  ActivationView.swift
//  AegisterVPN
//
//  Created by Aly Salman on 11/09/24.
//

import SwiftUI
import AuthenticationServices


struct ActivationView: View {
    @State private var activationKey = ""
    @State private var errorMessage: String?
    @State private var isActivated = false
    @State private var currentPage = 0
    @State private var showAuth = false
    @State private var showAlert = false
    
    @ObservedObject var vpnManager: VPNManager
    
    var body: some View {
        NavigationStack {
            TabView(selection: $currentPage) {
                // First Page
                VStack {
                    Image("Logo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 55, height: 55)
                        .padding(.bottom, 40)
                    
                    Text("Welcome to Aegister VPN")
                        .font(.largeTitle)
                        .bold()
                        .padding(.bottom, 20)
                    
                    Text("Your secure connection to the internet.")
                        .font(.subheadline)
                        .padding(.bottom, 40)
                    
                    Button(action: {
                        currentPage += 1
                    }) {
                        Text("Next")
                            .bold()
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .tag(0)
                .padding()
                
                // Second Page
                VStack {
                    Image(systemName: "key.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .padding(.bottom, 40)
                    
                    Text("Get Your Activation Key")
                        .font(.title)
                        .bold()
                        .padding(.bottom, 20)
                    
                    Text("Visit our platform app.aegister.com to obtain your activation key.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 40)
                    
                    Button(action: {
                        currentPage += 1
                    }) {
                        Text("Next")
                            .bold()
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .tag(1)
                .padding()
                
                VStack {
                    Image(systemName: "lock.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .padding(.bottom, 40)
                    
                    Text("Activate Your VPN")
                        .font(.title)
                        .bold()
                        .padding(.bottom, 20)
                    
                    TextField("Enter Activation Key", text: $activationKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                    }
                    
                    Button(action: {
                        fetchOVPNFile()
                    }) {
                        Text("Activate")
                            .bold()
                            .padding()
                            .background(activationKey.isEmpty || vpnManager.isLoading ? Color.gray : Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(activationKey.isEmpty || vpnManager.isLoading)
                    
                    HStack {
                        Text("Or")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        showAuth = true
                    }) {
                        Text("Sign In")
                            .bold()
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                    
                }
                .tag(2)
                .padding()
            }
            .tabViewStyle(PageTabViewStyle())
            .BackgroundViewLogo(logo: Image("Aegister"))
            .onAppear {
                UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color.accentColor)
                UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color.accentColor).withAlphaComponent(0.35)
            }
            .navigationDestination(isPresented: $isActivated) {
                ContentView()
            }
            .onChange(of:vpnManager.isConfigured)  {
                if vpnManager.isConfigured {
                    currentPage = 3
                } else {
                    errorMessage = "Failed to configure VPN"
                }
            }
            
            .sheet(isPresented: $showAuth, onDismiss: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    vpnManager.checkVPNConfiguration()
                    if !isActivated {
                        showAlert = true
                        
                    }
                }
            }) {
                WebAuthPresenter()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("No VPN Profile Found"),
                    message: Text("No VPN profile found associated with the account."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        
    }
    
    
    func fetchOVPNFile() {
        guard !activationKey.isEmpty else {
            errorMessage = "Activation key cannot be empty."
            return
        }
        
        errorMessage = nil
        vpnManager.fetchOVPNFile(with: activationKey)
    }
}

#Preview {
    ActivationView(vpnManager: VPNManager())
}

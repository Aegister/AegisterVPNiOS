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
                VStack {
                    Image("Logo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 65, height: 65)
                        .padding(.bottom, 40)
                    
                    Text("Welcome to Aegister VPN")
                        .font(Font.custom("Archivo", size: 27, relativeTo: .largeTitle ))
                        .bold()
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                    
                    Text("Your secure connection to the internet.")
                        .font(Font.custom("Archivo", size: 15, relativeTo: .subheadline ))
                        .padding(.bottom, 40)
                        .foregroundColor(.white)
                    
                    Button(action: {
                        currentPage += 1
                    }) {
                        Text("Next")
                            .bold()
                            .padding()
                            .font(Font.custom("Archivo", size: 19, relativeTo: .subheadline ))
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .tag(0)
                .padding()
                
                // Second Page
                VStack {
                    Image("Logo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 65, height: 65)
                        .padding(.bottom, 40)

                    Text("Get Your Activation Key")
                        .font(Font.custom("Archivo", size: 25, relativeTo: .title ))
                        .bold()
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                    
                    Text("""
                         Visit our platform app.aegister.com to obtain
                         your activation key or Login using your account.
                        """)
                        .multilineTextAlignment(.center)
                        .font(Font.custom("Archivo", size: 13, relativeTo: .subheadline ))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.bottom, 40)
                    
                    Button(action: {
                        currentPage += 1
                    }) {
                        Text("Next")
                            .bold()
                            .padding()
                            .font(Font.custom("Archivo", size: 19, relativeTo: .subheadline ))
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .tag(1)
                .padding()
                
                VStack {
                    Image("Logo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 65, height: 65)
                        .padding(.bottom, 40)

                    Text("Activate Your VPN")
                        .font(Font.custom("Archivo", size: 25, relativeTo: .title ))
                        .bold()
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                    
                    TextField("Enter Activation Key", text: $activationKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(Font.custom("Archivo", size: 13, relativeTo: .subheadline ))
                        .padding(.horizontal)
                        .foregroundColor(.white)
                        .frame(width: 275, height: 50)
                        .cornerRadius(8)
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
                            .font(Font.custom("Archivo", size: 19, relativeTo: .subheadline ))
                            .background(activationKey.isEmpty || vpnManager.isLoading ? Color.gray : Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.bottom, 25)
                    }
                    .disabled(activationKey.isEmpty || vpnManager.isLoading)
                    
                    HStack {
                        Rectangle()
                            .frame(width: 100, height: 1)
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        Text("Or")
                            .font(Font.custom("Archivo", size: 17, relativeTo: .subheadline ))
                            .foregroundColor(.white)

                        Rectangle()
                            .frame(width: 100, height: 1)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        showAuth = true
                    }) {
                        Text("Sign In")
                            .bold()
                            .padding()
                            .font(Font.custom("Archivo", size: 19, relativeTo: .subheadline ))
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.top, 25)
                    }
                    .padding()
                    if showAlert {
                        Text("Failed to configure VPN")
                            .bold()
                            .font(.headline)
                            .padding()
                            .foregroundColor(.red)
                    }
                    
                }
                .tag(2)
                .padding()
            }
            .tabViewStyle(PageTabViewStyle())
            .onAppear {
                UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color.accentColor)
                UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color.accentColor).withAlphaComponent(0.35)
            }
            .BackgroundViewLogo(logo: Image("Aegister"))
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

# Aegister VPN iOS Client

This is an iOS client app for OpenVPN built with Swift and the NetworkExtension framework. It uses an `.ovpn` configuration file to establish a VPN connection and offers a simple and user-friendly interface to connect/disconnect the VPN.

## Features

- Customizable UI to display VPN status (connecting, connected, disconnected).
- VPN status updates both in-app and from system settings.
- Automatic reconnect via OpenVPNReachability.

## Requirements

- iOS 13.0+
- Xcode 12+
- Swift 5.0+
- CocoaPods

## Getting Started

Follow these steps to set up and run the project on your machine.

### Step 1: Clone the Repository

```bash
git clone https://github.com/Aegister/AegisterVPNiOS.git
cd AegisterVPNiOS
```

### Step 2: Configuring the project. 

1. Open the project using `AegisterVPN.xcworkspace` file

2. Open your projeect settings > target > AegisterVPN > Signing & Capabilities, sign in using your developer account and change the `Bundle Identifier` to any of your choice. 

3. Do the same in settings > target > networkTarget > Signing & Capabilities.
   
4. Select your target device or simulator and click run!


## License

This project is licensed under the Apache License 2.0. See the [LICENSE](./LICENSE) file for more details.

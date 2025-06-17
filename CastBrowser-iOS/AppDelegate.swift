//
//  AppDelegate.swift
//  CastBrowser-iOS
//
//  Created by Claude Code on 08.06.2025.
//

import UIKit

#if !targetEnvironment(simulator) || !arch(x86_64)
    import GoogleCast
#endif

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        #if !targetEnvironment(simulator) || !arch(x86_64)
            // Configure Google Cast (disabled for x86_64 simulator due to Protobuf compatibility)
            do {
                let castOptions = GCKCastOptions(
                    discoveryCriteria: GCKDiscoveryCriteria(
                        applicationID: kGCKDefaultMediaReceiverApplicationID))
                castOptions.physicalVolumeButtonsWillControlDeviceVolume = true

                GCKCastContext.setSharedInstanceWith(castOptions)

                // Style the cast button
                GCKUICastButton.appearance().tintColor = UIColor.systemBlue

                print("✅ Cast SDK initialized successfully")

                // Start discovery immediately after initialization
                let discoveryManager = GCKCastContext.sharedInstance().discoveryManager
                discoveryManager.passiveScan = true
                discoveryManager.startDiscovery()
                print("✅ Cast discovery started with passive scan enabled")
            } catch {
                print("❌ Failed to initialize Cast SDK: \(error)")
                // Don't crash the app if Cast initialization fails
            }
        #endif

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(
            name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(
        _ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {
    }

    // MARK: URL Scheme Support

    func application(
        _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Handle castbrowser:// URL scheme
        if url.scheme == "castbrowser" {
            // You can add custom URL handling logic here
            return true
        }
        return false
    }
}

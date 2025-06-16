//
//  BrowserViewController.swift
//  CastBrowser-iOS
//
//  Created by Claude Code on 08.06.2025.
//

import UIKit
import WebKit
#if !targetEnvironment(simulator) || !arch(x86_64)
import GoogleCast
#endif

class BrowserViewController: UIViewController {
    
    // MARK: - Properties
    private var webView: WKWebView?
    #if !targetEnvironment(simulator) || !arch(x86_64)
    private var castButton: GCKUICastButton?
    private var sessionManager: GCKSessionManager?
    private var discoveryStatusTimer: Timer?
    #endif
    private var addressBar: UITextField?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupWebView()
        setupNavigationBar()
        loadInitialPage()
        
        #if !targetEnvironment(simulator) || !arch(x86_64)
        // Delay Cast setup to ensure everything is properly initialized
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            self.setupSessionManager()
            self.setupCastButton()
        }
        #endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        #if !targetEnvironment(simulator) || !arch(x86_64)
        // Ensure sessionManager is initialized
        if sessionManager == nil {
            setupSessionManager()
        }
        sessionManager?.add(self)
        // Ensure discovery is running when view appears
        startCastDiscovery()
        // Update discovery status when view appears
        updateDiscoveryStatus()
        #endif
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        #if !targetEnvironment(simulator) || !arch(x86_64)
        sessionManager?.remove(self)
        GCKCastContext.sharedInstance().discoveryManager.remove(self)
        // Stop the periodic timer
        discoveryStatusTimer?.invalidate()
        discoveryStatusTimer = nil
        #endif
    }
    
    deinit {
        print("BrowserViewController deinit")
        #if !targetEnvironment(simulator) || !arch(x86_64)
        // Clean up Cast SDK listeners
        sessionManager?.remove(self)
        GCKCastContext.sharedInstance().discoveryManager.remove(self)
        
        // Clean up timer
        discoveryStatusTimer?.invalidate()
        discoveryStatusTimer = nil
        #endif
        
        // Clean up WebView
        webView?.navigationDelegate = nil
        webView?.removeFromSuperview()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "CastBrowser"
        
        // Setup address bar
        guard addressBar == nil else { return } // Prevent double initialization
        addressBar = UITextField()
        addressBar?.borderStyle = .roundedRect
        addressBar?.placeholder = "Enter URL..."
        addressBar?.keyboardType = .URL
        addressBar?.autocapitalizationType = .none
        addressBar?.autocorrectionType = .no
        addressBar?.delegate = self
        addressBar?.returnKeyType = .go
        addressBar?.text = "https://www.youtube.com"
        
        guard let addressBar = addressBar else { return }
        view.addSubview(addressBar)
        addressBar.translatesAutoresizingMaskIntoConstraints = false
        
        // Address bar constraints
        #if !targetEnvironment(simulator) || !arch(x86_64)
        let trailingConstant: CGFloat = -80 // Leave space for cast button
        #else
        let trailingConstant: CGFloat = -16 // No cast button on x86_64 simulator
        #endif
        
        NSLayoutConstraint.activate([
            addressBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            addressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: trailingConstant),
            addressBar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        guard webView == nil else { return } // Prevent double initialization
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView?.navigationDelegate = self
        webView?.allowsBackForwardNavigationGestures = true
        
        guard let webView = webView, let addressBar = addressBar else { return }
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        // WebView constraints
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: addressBar.bottomAnchor, constant: 8),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    #if !targetEnvironment(simulator) || !arch(x86_64)
    private func setupCastButton() {
        // Ensure Cast context is properly initialized before creating button
        let castContext = GCKCastContext.sharedInstance()
        
        print("Cast context state: \(castContext)")
        print("Attempting to create Cast button...")
        
        // Try creating the cast button with error handling
        do {
            // Create with a larger initial frame to avoid sizing issues
            castButton = GCKUICastButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
            
            if let button = castButton {
                print("✅ Cast button created successfully")
                button.tintColor = .systemBlue
                
                // Add to view hierarchy first, then apply constraints
                view.addSubview(button)
                button.translatesAutoresizingMaskIntoConstraints = false
                
                // Cast button constraints (floating in top-right)
                if let addressBar = addressBar {
                    NSLayoutConstraint.activate([
                        button.centerYAnchor.constraint(equalTo: addressBar.centerYAnchor),
                        button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                        button.widthAnchor.constraint(equalToConstant: 44),
                        button.heightAnchor.constraint(equalToConstant: 44)
                    ])
                } else {
                    // Fallback positioning if addressBar is nil
                    NSLayoutConstraint.activate([
                        button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
                        button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                        button.widthAnchor.constraint(equalToConstant: 44),
                        button.heightAnchor.constraint(equalToConstant: 44)
                    ])
                }
                
                print("✅ Cast button constraints applied successfully")
                
                // Force layout update
                button.setNeedsLayout()
                button.layoutIfNeeded()
                
            } else {
                print("❌ Failed to create cast button - castButton is nil after initialization")
                // Try alternative approach
                createFallbackCastButton()
            }
            
        } catch {
            print("❌ Exception creating cast button: \(error)")
            createFallbackCastButton()
        }
        
        // Debug: Monitor Cast button visibility and discovery status
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.checkCastDeviceDiscovery()
        }
    }
    
    private func createFallbackCastButton() {
        print("Attempting fallback Cast button creation...")
        
        // Delay button creation to ensure Cast SDK is fully initialized
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            do {
                self.castButton = GCKUICastButton()
                
                if let button = self.castButton, let addressBar = self.addressBar {
                    print("✅ Fallback Cast button created successfully")
                    button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
                    button.tintColor = .systemBlue
                    
                    self.view.addSubview(button)
                    button.translatesAutoresizingMaskIntoConstraints = false
                    
                    NSLayoutConstraint.activate([
                        button.centerYAnchor.constraint(equalTo: addressBar.centerYAnchor),
                        button.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16),
                        button.widthAnchor.constraint(equalToConstant: 44),
                        button.heightAnchor.constraint(equalToConstant: 44)
                    ])
                    
                    print("✅ Fallback Cast button setup complete")
                } else {
                    print("❌ Fallback Cast button creation also failed - trying navigation bar approach")
                    self.addCastButtonToNavigationBar()
                }
            } catch {
                print("❌ Fallback Cast button creation failed: \(error)")
                self.addCastButtonToNavigationBar()
            }
        }
    }
    
    private func addCastButtonToNavigationBar() {
        print("Attempting to add Cast button to navigation bar...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            do {
                let navCastButton = GCKUICastButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
                if navCastButton != nil {
                    print("✅ Navigation Cast button created successfully")
                    navCastButton.tintColor = .systemBlue
                    
                    let castBarButton = UIBarButtonItem(customView: navCastButton)
                    
                    // Add to navigation bar alongside existing Cast Video button
                    if let existingButton = self.navigationItem.rightBarButtonItem {
                        self.navigationItem.rightBarButtonItems = [existingButton, castBarButton]
                    } else {
                        self.navigationItem.rightBarButtonItem = castBarButton
                    }
                    
                    print("✅ Cast button added to navigation bar successfully")
                } else {
                    print("❌ Navigation Cast button creation failed - button is nil")
                    self.diagnoseCastIssues()
                }
            } catch {
                print("❌ Navigation Cast button creation failed: \(error)")
                self.diagnoseCastIssues()
            }
        }
    }
    
    private func diagnoseCastIssues() {
        print("🔍 DIAGNOSING CAST SDK ISSUES 🔍")
        
        let castContext = GCKCastContext.sharedInstance()
        print("Cast Context: \(castContext)")
        print("Cast Context class: \(type(of: castContext))")
        
        let discoveryManager = castContext.discoveryManager
        print("Discovery Manager: \(discoveryManager)")
        print("Discovery Manager class: \(type(of: discoveryManager))")
        
        let sessionManager = castContext.sessionManager
        print("Session Manager: \(sessionManager)")
        print("Session Manager class: \(type(of: sessionManager))")
        
        // Try to get Cast options
        print("Cast Context State Details:")
        print("- Discovery state: \(discoveryManager.discoveryState)")
        print("- Device count: \(discoveryManager.deviceCount)")
        print("- Current session: \(sessionManager.currentSession?.description ?? "nil")")
        
        // Check if there are any specific Cast SDK initialization issues
        print("🔍 Attempting alternative Cast button creation methods...")
        
        // Try creating with different approaches
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.tryAlternativeCastButtonMethods()
        }
    }
    
    private func tryAlternativeCastButtonMethods() {
        print("🔧 Trying alternative Cast button creation methods...")
        
        // Method 1: Try creating without frame
        do {
            let testButton1 = GCKUICastButton()
            if testButton1 != nil {
                print("✅ Alternative method 1 (no frame) succeeded!")
                testButton1.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
                testButton1.tintColor = .systemBlue
                
                self.view.addSubview(testButton1)
                testButton1.translatesAutoresizingMaskIntoConstraints = false
                
                if let addressBar = self.addressBar {
                    NSLayoutConstraint.activate([
                        testButton1.centerYAnchor.constraint(equalTo: addressBar.centerYAnchor),
                        testButton1.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16),
                        testButton1.widthAnchor.constraint(equalToConstant: 44),
                        testButton1.heightAnchor.constraint(equalToConstant: 44)
                    ])
                }
                
                self.castButton = testButton1
                print("✅ Alternative Cast button successfully added to view!")
                return
            } else {
                print("❌ Alternative method 1 failed - button is nil")
            }
        } catch {
            print("❌ Alternative method 1 exception: \(error)")
        }
        
        // Method 2: Try with CGRect.zero
        do {
            let testButton2 = GCKUICastButton(frame: CGRect.zero)
            if testButton2 != nil {
                print("✅ Alternative method 2 (CGRect.zero) succeeded!")
                testButton2.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
                testButton2.tintColor = .systemBlue
                
                self.view.addSubview(testButton2)
                testButton2.translatesAutoresizingMaskIntoConstraints = false
                
                if let addressBar = self.addressBar {
                    NSLayoutConstraint.activate([
                        testButton2.centerYAnchor.constraint(equalTo: addressBar.centerYAnchor),
                        testButton2.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16),
                        testButton2.widthAnchor.constraint(equalToConstant: 44),
                        testButton2.heightAnchor.constraint(equalToConstant: 44)
                    ])
                }
                
                self.castButton = testButton2
                print("✅ Alternative Cast button (method 2) successfully added to view!")
                return
            } else {
                print("❌ Alternative method 2 failed - button is nil")
            }
        } catch {
            print("❌ Alternative method 2 exception: \(error)")
        }
        
        print("❌ All Cast button creation methods have failed")
        print("ℹ️  This may be due to:")
        print("   - Cast SDK configuration issues")
        print("   - Missing entitlements or permissions")
        print("   - App sandbox restrictions")
        print("   - iOS version compatibility issues")
        print("   - Network connectivity problems")
        
        print("🔧 Creating custom Cast button as fallback...")
        createCustomCastButton()
    }
    
    private func checkCastDeviceDiscovery() {
        let castContext = GCKCastContext.sharedInstance()
        let discoveryManager = castContext.discoveryManager
        
        print("=== Cast Device Discovery Status ===")
        print("Discovery Manager State: \(discoveryManager.discoveryState.rawValue)")
        print("Number of devices found: \(discoveryManager.deviceCount)")
        print("Cast button hidden: \(castButton?.isHidden ?? true)")
        print("Cast button alpha: \(castButton?.alpha ?? 0)")
        print("Current title: \(self.title ?? "nil")")
        
        // Log device details if any found
        for i in 0..<discoveryManager.deviceCount {
            let device = discoveryManager.device(at: i)
            print("Device \(i): \(device.friendlyName ?? "Unknown") - \(device.deviceID)")
        }
        
        // Update status regardless of device count
        DispatchQueue.main.async {
            self.updateDiscoveryStatus()
        }
        
        print("===================================")
    }
    
    private func showCastDeviceStatus() {
        // Use the unified status update method
        updateDiscoveryStatus()
    }
    
    private func setupSessionManager() {
        let castContext = GCKCastContext.sharedInstance()
        sessionManager = castContext.sessionManager
        
        // Monitor discovery manager for device changes
        castContext.discoveryManager.add(self)
        
        // Ensure discovery is started
        startCastDiscovery()
        
        // Set initial discovery status immediately
        DispatchQueue.main.async {
            self.updateDiscoveryStatus()
        }
    }
    
    private func startCastDiscovery() {
        let discoveryManager = GCKCastContext.sharedInstance().discoveryManager
        
        print("Starting Cast device discovery...")
        print("Current discovery state: \(discoveryManager.discoveryState.rawValue)")
        
        // Start discovery if it's not already running
        if discoveryManager.discoveryState != .running {
            discoveryManager.startDiscovery()
            print("Discovery start command sent")
        } else {
            print("Discovery already running")
        }
        
        // Force a discovery status update after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("Checking discovery status after start command...")
            self.updateDiscoveryStatus()
        }
        
        // Start periodic status updates if not already running
        if discoveryStatusTimer == nil {
            discoveryStatusTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                DispatchQueue.main.async {
                    self.updateDiscoveryStatus()
                }
            }
        }
    }
    
    private func updateDiscoveryStatus() {
        let discoveryManager = GCKCastContext.sharedInstance().discoveryManager
        let deviceCount = discoveryManager.deviceCount
        
        print("Updating discovery status - Device count: \(deviceCount), Discovery state: \(discoveryManager.discoveryState.rawValue)")
        
        if deviceCount > 0 {
            self.title = "CastBrowser"
        } else {
            // Check discovery state to provide appropriate feedback
            switch discoveryManager.discoveryState {
            case .stopped:
                self.title = "CastBrowser (Discovery stopped)"
                // Try to restart discovery if it's stopped
                print("Discovery is stopped, attempting to restart...")
                discoveryManager.startDiscovery()
            case .running:
                self.title = "CastBrowser (Searching...)"
            @unknown default:
                self.title = "CastBrowser (No Cast devices)"
            }
        }
        
        print("Title updated to: \(self.title ?? "nil")")
    }
    #endif
    
    private func setupNavigationBar() {
        // Add Cast Video button to navigation bar
        #if !targetEnvironment(simulator) || !arch(x86_64)
        let castVideoButton = UIBarButtonItem(title: "Cast Video", style: .plain, target: self, action: #selector(manualCastVideo))
        navigationItem.rightBarButtonItem = castVideoButton
        #endif
    }
    
    #if !targetEnvironment(simulator) || !arch(x86_64)
    private func createCustomCastButton() {
        print("Creating custom Cast button...")
        
        // Create a custom button that mimics GCKUICastButton functionality
        let customCastButton = UIButton(type: .system)
        customCastButton.setTitle("⎘", for: .normal) // Cast icon
        customCastButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        customCastButton.tintColor = .systemBlue
        customCastButton.backgroundColor = UIColor.systemBackground
        customCastButton.layer.cornerRadius = 22
        customCastButton.layer.borderWidth = 1
        customCastButton.layer.borderColor = UIColor.systemGray4.cgColor
        customCastButton.addTarget(self, action: #selector(customCastButtonTapped), for: .touchUpInside)
        
        // Add to view hierarchy
        view.addSubview(customCastButton)
        customCastButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply constraints
        if let addressBar = addressBar {
            NSLayoutConstraint.activate([
                customCastButton.centerYAnchor.constraint(equalTo: addressBar.centerYAnchor),
                customCastButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                customCastButton.widthAnchor.constraint(equalToConstant: 44),
                customCastButton.heightAnchor.constraint(equalToConstant: 44)
            ])
        }
        
        // Update button appearance based on Cast state
        updateCustomCastButtonAppearance(customCastButton)
        
        // Store reference for updates using a safe approach
        if objc_getAssociatedObject(self, "customCastButton") == nil {
            objc_setAssociatedObject(self, "customCastButton", customCastButton, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        print("✅ Custom Cast button created successfully")
    }
    
    @objc private func customCastButtonTapped() {
        print("Smart Cast button tapped")
        
        let castContext = GCKCastContext.sharedInstance()
        let discoveryManager = castContext.discoveryManager
        
        // Ensure we have a valid sessionManager
        if sessionManager == nil {
            sessionManager = castContext.sessionManager
        }
        
        guard let sessionManager = sessionManager else {
            showAlert(title: "Cast Error", message: "Cast session manager not available")
            return
        }
        
        // If already connected to a Cast device, try to cast video directly
        if let currentSession = sessionManager.currentCastSession {
            print("Already connected to Cast device, attempting to cast video...")
            detectAndCastVideo()
            return
        }
        
        // Check if any devices are available for connection
        if discoveryManager.deviceCount == 0 {
            showAlert(title: "No Cast Devices", 
                     message: "No Chromecast devices found on your network. Make sure your Chromecast is connected to the same Wi-Fi network as your device.")
            return
        }
        
        // Present Cast device selection for connection
        do {
            // Try to present the Cast dialog
            castContext.presentCastDialog()
            print("✅ Cast dialog presented")
        } catch {
            print("❌ Failed to present Cast dialog: \(error)")
            
            // Fallback: Show device list manually
            showCastDeviceList()
        }
    }
    
    private func showCastDeviceList() {
        let castContext = GCKCastContext.sharedInstance()
        let discoveryManager = castContext.discoveryManager
        
        let alert = UIAlertController(title: "Select Cast Device", message: "Choose a Chromecast device to connect to:", preferredStyle: .actionSheet)
        
        // Add device options
        for i in 0..<discoveryManager.deviceCount {
            let device = discoveryManager.device(at: i)
            let deviceName = device.friendlyName ?? "Unknown Device"
            
            let action = UIAlertAction(title: deviceName, style: .default) { _ in
                self.connectToCastDevice(device)
            }
            alert.addAction(action)
        }
        
        // Add cancel option
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Present on main thread
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
    
    private func connectToCastDevice(_ device: GCKDevice) {
        print("Connecting to Cast device: \(device.friendlyName ?? "Unknown")")
        
        let castContext = GCKCastContext.sharedInstance()
        let sessionManager = castContext.sessionManager
        
        // Start a cast session
        sessionManager.startSession(with: device)
    }
    
    private func updateCustomCastButtonAppearance(_ button: UIButton) {
        let sessionManager = GCKCastContext.sharedInstance().sessionManager
        
        if sessionManager.currentCastSession != nil {
            // Connected state
            button.tintColor = .systemGreen
            button.layer.borderColor = UIColor.systemGreen.cgColor
            button.setTitle("⎘", for: .normal) // Connected cast icon
        } else {
            // Disconnected state
            button.tintColor = .systemBlue
            button.layer.borderColor = UIColor.systemGray4.cgColor
            button.setTitle("⎘", for: .normal) // Default cast icon
        }
    }
    #else
    private func createCustomCastButton() {
        print("Custom Cast button not available on x86_64 simulator")
    }
    #endif
    
    @objc private func manualCastVideo() {
        #if !targetEnvironment(simulator) || !arch(x86_64)
        let discoveryManager = GCKCastContext.sharedInstance().discoveryManager
        
        // Check if any Cast devices are available
        if discoveryManager.deviceCount == 0 {
            showAlert(title: "No Cast Devices", message: "No Chromecast devices found on your network. Make sure your Chromecast is connected to the same Wi-Fi network as your device.\n\nThe Cast button (⎘) will appear automatically when devices are found.")
            return
        }
        
        // Ensure sessionManager is available
        if sessionManager == nil {
            sessionManager = GCKCastContext.sharedInstance().sessionManager
        }
        
        // Check if connected to a Cast session
        guard let sessionManager = sessionManager,
              sessionManager.currentCastSession != nil else {
            showAlert(title: "Connect to Chromecast", message: "Please connect to a Chromecast device first by tapping the Cast button (⎘) in the top-right corner.")
            return
        }
        
        detectAndCastVideo()
        #else
        showAlert(title: "Cast Not Available", message: "Casting is not available on the simulator. Please test on a physical device.")
        #endif
    }
    
    private func loadInitialPage() {
        guard let addressBar = addressBar,
              let webView = webView,
              let urlString = addressBar.text,
              let url = URL(string: urlString) else {
            print("Failed to load initial page: missing components")
            return
        }
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    // MARK: - Video Detection and Casting
    
    #if !targetEnvironment(simulator) || !arch(x86_64)
    private func detectAndCastVideo() {
        let javascript = """
            (function() {
                // Enhanced video detection function with debugging
                function findVideoUrl() {
                    var debugInfo = [];
                    debugInfo.push('Current URL: ' + window.location.href);
                    debugInfo.push('Current hostname: ' + window.location.hostname);
                    
                    // Method 1: Find HTML5 video elements (most reliable)
                    var videos = document.querySelectorAll('video');
                    debugInfo.push('Found ' + videos.length + ' video elements');
                    
                    for (var i = 0; i < videos.length; i++) {
                        var video = videos[i];
                        debugInfo.push('Video ' + i + ': currentSrc=' + (video.currentSrc || 'none') + ', src=' + (video.src || 'none'));
                        
                        // Check if video is currently playing or has been played
                        if (!video.paused || video.currentTime > 0) {
                            debugInfo.push('Found active video at index ' + i);
                            
                            // Check currentSrc first (most reliable for actual playing content)
                            if (video.currentSrc && video.currentSrc.trim() !== '' && video.currentSrc !== window.location.href) {
                                return {
                                    url: video.currentSrc,
                                    type: 'video-currentSrc-active',
                                    element: 'video',
                                    debug: debugInfo
                                };
                            }
                        }
                        
                        // Check any video with currentSrc
                        if (video.currentSrc && video.currentSrc.trim() !== '' && video.currentSrc !== window.location.href) {
                            return {
                                url: video.currentSrc,
                                type: 'video-currentSrc',
                                element: 'video',
                                debug: debugInfo
                            };
                        }
                        
                        // Check src attribute
                        if (video.src && video.src.trim() !== '' && video.src !== window.location.href) {
                            return {
                                url: video.src,
                                type: 'video-src',
                                element: 'video',
                                debug: debugInfo
                            };
                        }
                        
                        // Check source elements within video
                        var sources = video.querySelectorAll('source');
                        for (var j = 0; j < sources.length; j++) {
                            if (sources[j].src && sources[j].src.trim() !== '') {
                                return {
                                    url: sources[j].src,
                                    type: 'video-source',
                                    element: 'video',
                                    debug: debugInfo
                                };
                            }
                        }
                    }
                    
                    // Method 2: YouTube-specific detection
                    if (window.location.hostname.includes('youtube.com') || window.location.hostname.includes('youtu.be')) {
                        debugInfo.push('YouTube detected, looking for video ID');
                        
                        // Extract video ID from URL
                        var videoId = null;
                        var url = window.location.href;
                        
                        // Standard YouTube URLs
                        var match = url.match(/[?&]v=([a-zA-Z0-9_-]+)/);
                        if (match) {
                            videoId = match[1];
                        } else {
                            // Shortened YouTube URLs
                            match = url.match(/youtu\\.be\\/([a-zA-Z0-9_-]+)/);
                            if (match) {
                                videoId = match[1];
                            }
                        }
                        
                        if (videoId) {
                            debugInfo.push('Found YouTube video ID: ' + videoId);
                            // Create a direct YouTube URL that Chromecast can handle
                            return {
                                url: 'https://www.youtube.com/watch?v=' + videoId,
                                type: 'youtube-url',
                                element: 'page-url',
                                debug: debugInfo
                            };
                        }
                    }
                    
                    // Method 3: Look for iframe with video content
                    var iframes = document.querySelectorAll('iframe');
                    debugInfo.push('Found ' + iframes.length + ' iframe elements');
                    
                    for (var k = 0; k < iframes.length; k++) {
                        var iframe = iframes[k];
                        var src = iframe.src || '';
                        debugInfo.push('Iframe ' + k + ': src=' + (src || 'none'));
                        
                        // Check for common video embed patterns
                        if (src && src.trim() !== '') {
                            // Known video platforms
                            if (src.includes('youtube.com') || src.includes('youtu.be') ||
                                src.includes('vimeo.com') || src.includes('dailymotion.com') ||
                                src.includes('twitch.tv') || src.includes('.mp4') ||
                                src.includes('.webm') || src.includes('.m3u8')) {
                                debugInfo.push('Found video iframe (known platform): ' + src);
                                return {
                                    url: src,
                                    type: 'iframe-embed',
                                    element: 'iframe',
                                    debug: debugInfo
                                };
                            }
                            
                            // Check for potential streaming services by URL patterns
                            if (src.includes('/embed/') || src.includes('/player/') || 
                                src.includes('/watch/') || src.includes('/video/') ||
                                src.includes('stream') || src.includes('play') ||
                                src.includes('/content/')) {
                                debugInfo.push('Found potential video iframe (embed pattern): ' + src);
                                return {
                                    url: src,
                                    type: 'iframe-custom-stream',
                                    element: 'iframe',
                                    debug: debugInfo
                                };
                            }
                        }
                        
                        // Additional check for data-src attribute (lazy loaded iframes)
                        var dataSrc = iframe.getAttribute('data-src') || '';
                        if (dataSrc && dataSrc.trim() !== '') {
                            debugInfo.push('Iframe ' + k + ': data-src=' + dataSrc);
                            // Known video platforms
                            if (dataSrc.includes('youtube.com') || dataSrc.includes('youtu.be') ||
                                dataSrc.includes('vimeo.com') || dataSrc.includes('dailymotion.com') ||
                                dataSrc.includes('twitch.tv') || dataSrc.includes('.mp4') ||
                                dataSrc.includes('.webm') || dataSrc.includes('.m3u8')) {
                                debugInfo.push('Found video iframe in data-src (known platform): ' + dataSrc);
                                return {
                                    url: dataSrc,
                                    type: 'iframe-data-src',
                                    element: 'iframe',
                                    debug: debugInfo
                                };
                            }
                            
                            // Check for potential streaming services by URL patterns
                            if (dataSrc.includes('/embed/') || dataSrc.includes('/player/') || 
                                dataSrc.includes('/watch/') || dataSrc.includes('/video/') ||
                                dataSrc.includes('stream') || dataSrc.includes('play') ||
                                dataSrc.includes('/content/')) {
                                debugInfo.push('Found potential video iframe in data-src (embed pattern): ' + dataSrc);
                                return {
                                    url: dataSrc,
                                    type: 'iframe-custom-stream-data',
                                    element: 'iframe',
                                    debug: debugInfo
                                };
                            }
                        }
                    }
                    
                    // Method 4: Look for video URLs in scripts and data attributes
                    var videoUrlPattern = /https?:\\/\\/[^\\s"'<>\\)\\(]*\\.(?:mp4|webm|avi|mov|m3u8|mpd)(?:[?#][^\\s"'<>\\)\\(]*)?/gi;
                    var scripts = document.querySelectorAll('script');
                    
                    for (var s = 0; s < scripts.length; s++) {
                        var script = scripts[s];
                        var content = script.textContent || script.innerHTML || '';
                        var matches = content.match(videoUrlPattern);
                        
                        if (matches && matches.length > 0) {
                            // Filter out likely non-video URLs
                            for (var match of matches) {
                                if (!match.includes('google') && !match.includes('analytics') && 
                                    !match.includes('ads') && !match.includes('tracking')) {
                                    return {
                                        url: matches[0],
                                        type: 'script-content',
                                        element: 'script',
                                        debug: debugInfo
                                    };
                                }
                            }
                        }
                    }
                    
                    // Method 5: Check all elements for data attributes with video URLs
                    var allElements = document.querySelectorAll('*');
                    var checkedCount = 0;
                    
                    for (var l = 0; l < Math.min(allElements.length, 1000); l++) { // Limit to first 1000 elements for performance
                        var element = allElements[l];
                        checkedCount++;
                        
                        // Check data attributes
                        for (var attr of element.attributes || []) {
                            if (attr.value && attr.value.match(videoUrlPattern)) {
                                return {
                                    url: attr.value,
                                    type: 'data-attribute',
                                    element: element.tagName.toLowerCase(),
                                    debug: debugInfo
                                };
                            }
                        }
                    }
                    
                    debugInfo.push('Checked ' + checkedCount + ' elements for data attributes');
                    
                    // Method 6: Last resort - check if current URL itself is a video
                    var currentUrl = window.location.href;
                    if (currentUrl.includes('.mp4') || currentUrl.includes('.webm') || 
                        currentUrl.includes('.m3u8') || currentUrl.includes('.avi') || 
                        currentUrl.includes('.mov') || currentUrl.includes('.mpd')) {
                        debugInfo.push('Current URL appears to be a direct video link');
                        return {
                            url: currentUrl,
                            type: 'direct-video-url',
                            element: 'page-url',
                            debug: debugInfo
                        };
                    }
                    
                    // Return debug info even if no video found
                    return {
                        url: null,
                        type: 'no-video-found',
                        element: 'none',
                        debug: debugInfo
                    };
                }
                
                var result = findVideoUrl();
                console.log('Video detection result:', result);
                return result;
            })();
        """
        
        guard let webView = webView else {
            showAlert(title: "Error", message: "WebView not available")
            return
        }
        
        webView.evaluateJavaScript(javascript) { [weak self] (result, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("JavaScript evaluation error: \(error)")
                self.showAlert(title: "Script Error", message: "Error detecting video: \(error.localizedDescription)")
                return
            }
            
            // Handle both old string format and new object format
            var videoURL: String?
            var detectionInfo: String?
            var debugInfo: [String] = []
            
            if let resultDict = result as? [String: Any] {
                videoURL = resultDict["url"] as? String
                let type = resultDict["type"] as? String ?? "unknown"
                let element = resultDict["element"] as? String ?? "unknown"
                debugInfo = resultDict["debug"] as? [String] ?? []
                detectionInfo = "Detected via \(type) in \(element) element"
                
                // Print debug info to console
                print("Video detection debug info:")
                for debug in debugInfo {
                    print("  - \(debug)")
                }
            } else if let urlString = result as? String {
                videoURL = urlString
                detectionInfo = "Detected via legacy method"
            }
            
            if let url = videoURL, !url.isEmpty, url != "null" {
                print("Video URL found: \(url)")
                if let info = detectionInfo {
                    print("Detection info: \(info)")
                }
                self.castVideo(url: url)
            } else {
                // Create detailed error message with debug info
                var debugMessage = "No video content could be detected on this page."
                
                if !debugInfo.isEmpty {
                    debugMessage += "\n\nDebug info:\n"
                    for (index, debug) in debugInfo.enumerated() {
                        debugMessage += "• \(debug)"
                        if index < debugInfo.count - 1 {
                            debugMessage += "\n"
                        }
                    }
                }
                
                debugMessage += "\n\nTips:\n• Try playing the video first\n• Make sure the video is visible on the page\n• Some streaming services may not be supported"
                
                self.showAlert(title: "No Video Found", message: debugMessage)
            }
        }
    }
    
    private func castVideo(url: String) {
        // Validate Cast context first
        let castContext = GCKCastContext.sharedInstance()
        let currentSessionManager = sessionManager ?? castContext.sessionManager
        
        guard let session = currentSessionManager.currentCastSession else {
            showAlert(title: "Cast Error", message: "No active Cast session found. Please connect to a Chromecast device first by tapping the Cast button.")
            return
        }
        
        guard let remoteMediaClient = session.remoteMediaClient else {
            showAlert(title: "Cast Error", message: "Cast session is not ready for media playback. Please try again.")
            return
        }
        
        guard let videoURL = URL(string: url) else {
            showAlert(title: "Invalid URL", message: "The video URL is not valid: \(url)")
            return
        }
        
        // Detect content type based on URL
        let contentType = detectContentType(from: url)
        
        let metadata = GCKMediaMetadata(metadataType: .movie)
        metadata.setString("Video from CastBrowser", forKey: kGCKMetadataKeyTitle)
        metadata.setString(videoURL.absoluteString, forKey: kGCKMetadataKeySubtitle)
        
        // Determine stream type
        let streamType: GCKMediaStreamType = url.contains(".m3u8") || url.contains("manifest") ? .live : .buffered
        
        let mediaInfo = GCKMediaInformation(
            contentID: videoURL.absoluteString,
            streamType: streamType,
            contentType: contentType,
            metadata: metadata,
            streamDuration: 0,
            mediaTracks: nil,
            textTrackStyle: nil,
            customData: nil
        )
        
        let request = remoteMediaClient.loadMedia(mediaInfo)
        request.delegate = self
        
        showAlert(title: "Casting Started", message: "Attempting to cast video to your Chromecast device.\n\nURL: \(url)\nType: \(contentType)")
    }
    
    private func detectContentType(from url: String) -> String {
        let lowercaseUrl = url.lowercased()
        
        if lowercaseUrl.contains(".mp4") {
            return "video/mp4"
        } else if lowercaseUrl.contains(".webm") {
            return "video/webm"
        } else if lowercaseUrl.contains(".m3u8") {
            return "application/x-mpegURL"
        } else if lowercaseUrl.contains(".mpd") {
            return "application/dash+xml"
        } else if lowercaseUrl.contains(".avi") {
            return "video/x-msvideo"
        } else if lowercaseUrl.contains(".mov") {
            return "video/quicktime"
        } else if lowercaseUrl.contains(".wmv") {
            return "video/x-ms-wmv"
        } else if lowercaseUrl.contains("youtube.com") || lowercaseUrl.contains("youtu.be") {
            return "video/mp4" // YouTube videos are typically MP4
        } else if lowercaseUrl.contains("vimeo.com") {
            return "video/mp4" // Vimeo videos are typically MP4
        } else {
            return "video/mp4" // Default fallback
        }
    }
    #endif
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}

#if !targetEnvironment(simulator) || !arch(x86_64)
// MARK: - GCKSessionManagerListener

extension BrowserViewController: GCKSessionManagerListener {
    
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        print("Cast session started")
        showAlert(title: "Cast Connected", message: "Connected to Cast device. Tap the Cast button (⎘) to cast video content from the current page.")
        
        // Update custom Cast button appearance
        if let customButton = objc_getAssociatedObject(self, "customCastButton") as? UIButton {
            updateCustomCastButtonAppearance(customButton)
        }
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didResumeSession session: GCKSession) {
        print("Cast session resumed")
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        print("Cast session ended")
        if let error = error {
            print("Session ended with error: \(error)")
        }
        
        // Update custom Cast button appearance
        if let customButton = objc_getAssociatedObject(self, "customCastButton") as? UIButton {
            updateCustomCastButtonAppearance(customButton)
        }
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKSession, withError error: Error) {
        print("Failed to start cast session: \(error)")
        showAlert(title: "Cast Error", message: "Failed to start casting session: \(error.localizedDescription)")
    }
}

// MARK: - GCKRequestDelegate

extension BrowserViewController: GCKRequestDelegate {
    
    func requestDidComplete(_ request: GCKRequest) {
        print("Cast request completed successfully")
    }
    
    func request(_ request: GCKRequest, didFailWithError error: GCKError) {
        print("Cast request failed: \(error)")
        showAlert(title: "Cast Error", message: "Failed to cast video: \(error.localizedDescription)")
    }
}

// MARK: - GCKDiscoveryManagerListener

extension BrowserViewController: GCKDiscoveryManagerListener {
    
    func didStartDiscovery(for deviceCategory: String) {
        print("Cast device discovery started for category: \(deviceCategory)")
        DispatchQueue.main.async {
            self.updateDiscoveryStatus()
        }
    }
    
    func willUpdateDeviceList() {
        print("Cast device list will update")
    }
    
    func didUpdateDeviceList() {
        print("Cast device list updated")
        DispatchQueue.main.async {
            self.updateDiscoveryStatus()
        }
    }
    
    func didInsert(_ device: GCKDevice, at index: UInt) {
        print("Cast device found: \(device.friendlyName ?? "Unknown") at index \(index)")
        DispatchQueue.main.async {
            self.showAlert(title: "Cast Device Found", message: "Found Chromecast: \(device.friendlyName ?? "Unknown Device")")
            self.updateDiscoveryStatus()
        }
    }
    
    func didUpdate(_ device: GCKDevice, at index: UInt) {
        print("Cast device updated: \(device.friendlyName ?? "Unknown") at index \(index)")
        DispatchQueue.main.async {
            self.updateDiscoveryStatus()
        }
    }
    
    func didRemove(_ device: GCKDevice, at index: UInt) {
        print("Cast device removed: \(device.friendlyName ?? "Unknown") at index \(index)")
        DispatchQueue.main.async {
            self.updateDiscoveryStatus()
        }
    }
}
#endif

// MARK: - WKNavigationDelegate

extension BrowserViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Update address bar with current URL
        if let url = webView.url {
            addressBar?.text = url.absoluteString
        }
        
        // Inject video detection helper script
        #if !targetEnvironment(simulator) || !arch(x86_64)
        injectVideoDetectionHelper()
        #endif
    }
    
    #if !targetEnvironment(simulator) || !arch(x86_64)
    private func injectVideoDetectionHelper() {
        // Check if we have permission to inject scripts
        guard let webView = webView, let url = webView.url, url.scheme == "https" || url.scheme == "http" else {
            print("CastBrowser: Skipping script injection for non-web content")
            return
        }
        
        let helperScript = """
            // CastBrowser Video Detection Helper
            (function() {
                'use strict';
                
                // Prevent multiple injections
                if (window.castBrowserInjected) {
                    return;
                }
                window.castBrowserInjected = true;
                
                console.log('CastBrowser: Video detection helper injected');
                
                // Watch for video elements being added to the page
                var observer = new MutationObserver(function(mutations) {
                    mutations.forEach(function(mutation) {
                        if (mutation.type === 'childList') {
                            mutation.addedNodes.forEach(function(node) {
                                if (node.nodeType === 1) { // Element node
                                    if (node.tagName === 'VIDEO' || (node.querySelector && node.querySelector('video'))) {
                                        console.log('CastBrowser: New video element detected');
                                    }
                                }
                            });
                        }
                    });
                });
                
                // Only observe if document.body exists
                if (document.body) {
                    observer.observe(document.body, {
                        childList: true,
                        subtree: true
                    });
                }
                
                // Log initial video elements
                var videos = document.querySelectorAll('video');
                if (videos.length > 0) {
                    console.log('CastBrowser: Found ' + videos.length + ' video elements on page load');
                } else {
                    console.log('CastBrowser: No video elements found on initial page load');
                }
            })();
        """
        
        webView.evaluateJavaScript(helperScript) { [weak self] _, error in
            if let error = error {
                print("Error injecting video detection helper: \(error)")
                // Don't show alert for script injection errors as they're not critical
            } else {
                print("Video detection helper script injected successfully")
            }
        }
    }
    #endif
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showAlert(title: "Loading Error", message: "Failed to load page: \(error.localizedDescription)")
    }
}

// MARK: - UITextFieldDelegate

extension BrowserViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        guard let urlString = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), 
              !urlString.isEmpty else {
            return true
        }
        
        // Validate and sanitize URL
        guard let validatedURL = validateAndSanitizeURL(urlString) else {
            showAlert(title: "Invalid URL", message: "Please enter a valid URL.")
            return true
        }
        
        let request = URLRequest(url: validatedURL)
        webView?.load(request)
        
        return true
    }
    
    private func validateAndSanitizeURL(_ urlString: String) -> URL? {
        var finalURLString = urlString
        
        // Remove potentially dangerous schemes
        let dangerousSchemes = ["javascript:", "data:", "file:", "about:"]
        for scheme in dangerousSchemes {
            if finalURLString.lowercased().hasPrefix(scheme) {
                return nil
            }
        }
        
        // Add https:// if no scheme is present
        if !finalURLString.hasPrefix("http://") && !finalURLString.hasPrefix("https://") {
            finalURLString = "https://\(finalURLString)"
        }
        
        // Basic URL validation
        guard let url = URL(string: finalURLString),
              let scheme = url.scheme,
              ["http", "https"].contains(scheme.lowercased()),
              let host = url.host,
              !host.isEmpty else {
            return nil
        }
        
        return url
    }
}
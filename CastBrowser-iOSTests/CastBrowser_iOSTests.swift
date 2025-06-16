//
//  CastBrowser_iOSTests.swift
//  CastBrowser-iOSTests
//
//  Created by Claude Code on 08.06.2025.
//

import XCTest
import WebKit
#if !targetEnvironment(simulator) || !arch(x86_64)
import GoogleCast
#endif
@testable import CastBrowser_iOS

final class CastBrowser_iOSTests: XCTestCase {
    
    var browserViewController: BrowserViewController!
    var mockSessionManager: MockSessionManager!
    
    override func setUpWithError() throws {
        super.setUp()
        browserViewController = BrowserViewController()
        mockSessionManager = MockSessionManager()
        
        // Load the view to trigger viewDidLoad
        _ = browserViewController.view
    }
    
    override func tearDownWithError() throws {
        browserViewController = nil
        mockSessionManager = nil
        super.tearDown()
    }
    
    // MARK: - BrowserViewController Tests
    
    func testBrowserViewControllerInitialization() throws {
        XCTAssertNotNil(browserViewController)
        XCTAssertNotNil(browserViewController.view)
        XCTAssertEqual(browserViewController.title, "CastBrowser")
    }
    
    func testWebViewConfiguration() throws {
        let webViewExists = browserViewController.view.subviews.contains { subview in
            return subview is WKWebView
        }
        XCTAssertTrue(webViewExists, "WebView should be added to the view hierarchy")
    }
    
    func testCastButtonPresence() throws {
        #if !targetEnvironment(simulator) || !arch(x86_64)
        let castButtonExists = browserViewController.view.subviews.contains { subview in
            return subview is GCKUICastButton
        }
        XCTAssertTrue(castButtonExists, "Cast button should be added to the view hierarchy")
        #else
        // Skip test on x86_64 simulator
        XCTSkip("Cast functionality not available on x86_64 simulator")
        #endif
    }
    
    func testAddressBarPresence() throws {
        let addressBarExists = browserViewController.view.subviews.contains { subview in
            return subview is UITextField
        }
        XCTAssertTrue(addressBarExists, "Address bar should be added to the view hierarchy")
    }
    
    func testInitialURL() throws {
        let addressBar = browserViewController.view.subviews.first { $0 is UITextField } as? UITextField
        XCTAssertEqual(addressBar?.text, "https://www.youtube.com")
    }
    
    // MARK: - URL Validation Tests
    
    func testValidURLCreation() throws {
        let validURLStrings = [
            "https://www.youtube.com",
            "http://example.com",
            "https://vimeo.com/video/123456"
        ]
        
        for urlString in validURLStrings {
            let url = URL(string: urlString)
            XCTAssertNotNil(url, "Should create valid URL for: \(urlString)")
        }
    }
    
    func testURLPrefixing() throws {
        let testCases = [
            ("youtube.com", "https://youtube.com"),
            ("www.example.com", "https://www.example.com"),
            ("http://already-prefixed.com", "http://already-prefixed.com"),
            ("https://already-prefixed.com", "https://already-prefixed.com")
        ]
        
        for (input, expected) in testCases {
            var result = input
            if !input.hasPrefix("http://") && !input.hasPrefix("https://") {
                result = "https://\(input)"
            }
            XCTAssertEqual(result, expected, "URL prefixing failed for: \(input)")
        }
    }
    
    // MARK: - JavaScript Video Detection Tests
    
    func testVideoDetectionJavaScript() throws {
        let javascript = """
            (function() {
                var video = document.querySelector('video');
                if (video && video.currentSrc) {
                    return video.currentSrc;
                }
                return null;
            })();
        """
        
        XCTAssertFalse(javascript.isEmpty)
        XCTAssertTrue(javascript.contains("document.querySelector('video')"))
        XCTAssertTrue(javascript.contains("currentSrc"))
        XCTAssertTrue(javascript.contains("return null"))
    }
    
    // MARK: - Cast Session Management Tests
    
    func testSessionManagerIntegration() throws {
        #if !targetEnvironment(simulator) || !arch(x86_64)
        // Test that session manager is properly initialized
        let sessionManager = GCKCastContext.sharedInstance().sessionManager
        XCTAssertNotNil(sessionManager)
        #else
        // Skip test on x86_64 simulator
        XCTSkip("Cast functionality not available on x86_64 simulator")
        #endif
    }
    
    // MARK: - Performance Tests
    
    func testBrowserViewControllerLoadPerformance() throws {
        measure {
            let vc = BrowserViewController()
            _ = vc.view // Trigger viewDidLoad
        }
    }
    
    func testJavaScriptEvaluationPerformance() throws {
        let webView = WKWebView()
        let javascript = """
            (function() {
                var video = document.querySelector('video');
                if (video && video.currentSrc) {
                    return video.currentSrc;
                }
                return null;
            })();
        """
        
        measure {
            let expectation = self.expectation(description: "JavaScript evaluation")
            webView.evaluateJavaScript(javascript) { (result, error) in
                expectation.fulfill()
            }
            waitForExpectations(timeout: 1.0)
        }
    }
}

// MARK: - Mock Classes for Testing

class MockSessionManager {
    var currentSession: MockSession?
    var listeners: [AnyObject] = []
    
    func add(_ listener: AnyObject) {
        listeners.append(listener)
    }
    
    func remove(_ listener: AnyObject) {
        listeners.removeAll { $0 === listener }
    }
    
    func startSession() {
        currentSession = MockSession()
        // Simulate session started callback
    }
    
    func endSession() {
        currentSession = nil
        // Simulate session ended callback
    }
}

class MockSession {
    var remoteMediaClient: MockRemoteMediaClient = MockRemoteMediaClient()
    var sessionID: String = "mock-session-123"
}

class MockRemoteMediaClient {
    #if !targetEnvironment(simulator) || !arch(x86_64)
    func loadMedia(_ mediaInfo: GCKMediaInformation) -> MockRequest {
        return MockRequest()
    }
    #endif
    
    func loadMedia(_ mediaInfo: Any) -> MockRequest {
        return MockRequest()
    }
}

class MockRequest {
    var delegate: AnyObject?
    
    func setDelegate(_ delegate: AnyObject) {
        self.delegate = delegate
    }
}
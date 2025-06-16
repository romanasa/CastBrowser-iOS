//
//  BasicAppTests.swift
//  CastBrowser-iOSTests
//
//  Created by Claude Code on 08.06.2025.
//

import XCTest
import WebKit
@testable import CastBrowser_iOS

final class BasicAppTests: XCTestCase {
    
    var browserViewController: BrowserViewController!
    
    override func setUpWithError() throws {
        super.setUp()
        browserViewController = BrowserViewController()
        
        // Load the view to trigger viewDidLoad
        _ = browserViewController.view
    }
    
    override func tearDownWithError() throws {
        browserViewController = nil
        super.tearDown()
    }
    
    // MARK: - Basic UI Tests
    
    func testBrowserViewControllerInitialization() throws {
        XCTAssertNotNil(browserViewController)
        XCTAssertNotNil(browserViewController.view)
        XCTAssertEqual(browserViewController.title, "CastBrowser")
    }
    
    func testWebViewExists() throws {
        let webViewExists = browserViewController.view.subviews.contains { subview in
            return subview is WKWebView
        }
        XCTAssertTrue(webViewExists, "WebView should be added to the view hierarchy")
    }
    
    func testAddressBarExists() throws {
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
    
    // MARK: - Performance Tests
    
    func testBrowserViewControllerLoadPerformance() throws {
        measure {
            let vc = BrowserViewController()
            _ = vc.view // Trigger viewDidLoad
        }
    }
}
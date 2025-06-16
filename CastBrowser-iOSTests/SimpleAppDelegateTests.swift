//
//  SimpleAppDelegateTests.swift
//  CastBrowser-iOSTests
//
//  Created by Claude Code on 08.06.2025.
//

import XCTest
@testable import CastBrowser_iOS

final class SimpleAppDelegateTests: XCTestCase {
    
    var appDelegate: AppDelegate!
    
    override func setUpWithError() throws {
        super.setUp()
        appDelegate = AppDelegate()
    }
    
    override func tearDownWithError() throws {
        appDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Basic AppDelegate Tests
    
    func testAppDelegateExists() throws {
        XCTAssertNotNil(appDelegate)
    }
    
    func testApplicationDidFinishLaunching() throws {
        let application = UIApplication.shared
        let result = appDelegate.application(application, didFinishLaunchingWithOptions: nil)
        XCTAssertTrue(result, "App should finish launching successfully")
    }
    
    // MARK: - URL Scheme Tests
    
    func testURLSchemeHandling() throws {
        let testURL = URL(string: "castbrowser://test")!
        let result = appDelegate.application(UIApplication.shared, open: testURL, options: [:])
        XCTAssertTrue(result, "Should handle castbrowser:// URL scheme")
    }
    
    func testInvalidURLSchemeHandling() throws {
        let testURL = URL(string: "invalid://test")!
        let result = appDelegate.application(UIApplication.shared, open: testURL, options: [:])
        XCTAssertFalse(result, "Should not handle invalid URL schemes")
    }
    
    // MARK: - Performance Tests
    
    func testAppLaunchPerformance() throws {
        measure {
            let delegate = AppDelegate()
            _ = delegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)
        }
    }
}
//
//  AppDelegate.swift
//  RAMControls
//
//  Created by Alex K. on 12/10/16.
//  Copyright © 2016 Alex K. All rights reserved.
//

import UIKit
import Firebase
import ElongationPreview
import OAuthSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?


  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    
    configureNavigationBar()
    AppAnalytics.configuration([.google])
    configureElongationPreviewControl()
    ReelSearchViewModel.shared.initializeDatabase()
    
    return true
  }
}

// MARK: Handle callback url
extension AppDelegate {
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if (url.host == "oauth") {
            OAuthSwift.handle(url: url)
        }
        return true
    }
}

extension AppDelegate {
  
    fileprivate func configureNavigationBar() {
        //transparent background
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().isTranslucent = true
        
        
        if let font = UIFont(name: "Avenir-medium", size: 18) {
            UINavigationBar.appearance().titleTextAttributes = [
                NSAttributedStringKey.foregroundColor: UIColor.white,
                NSAttributedStringKey.font: font,
            ]
        }
    }
    
  fileprivate func configureElongationPreviewControl() {
    // Customize ElongationConfig
    var config = ElongationConfig()
    config.scaleViewScaleFactor = 0.9
    config.topViewHeight = 190
    config.bottomViewHeight = 170
    config.bottomViewOffset = 20
    config.parallaxFactor = 100
    config.separatorHeight = 0.5
    config.separatorColor = UIColor.white
    
    // Durations for presenting/dismissing detail screen
    config.detailPresentingDuration = 0.4
    config.detailDismissingDuration = 0.4
    
    // Customize behaviour
    config.headerTouchAction = .collpaseOnBoth
    
    // Save created appearance object as default
    ElongationConfig.shared = config
  }
  
}

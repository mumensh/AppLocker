//
//  AppDelegate.swift
//  PasscodeLock
//
//  Created by Oleg Ryasnoy on 18.04.17.
//  Copyright © 2017 Oleg Ryasnoy. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    return true
  }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        if AppLocker.hasPinCode() {
            var config: ALAppearance = ALAppearance()
            config.backgroundColor = .white
            config.foregroundColor = .black
            config.hightlightColor = .blue
            config.isSensorsEnabled = true
            AppLocker.present(with: .validate, and: config)
        }
    }
}


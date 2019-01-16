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
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        //Check if there is a saved pin code
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


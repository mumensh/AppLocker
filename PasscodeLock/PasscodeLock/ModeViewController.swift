//
//  ModeViewController.swift
//  PasscodeLock
//
//  Created by Oleg Ryasnoy on 19.04.17.
//  Copyright © 2017 Oleg Ryasnoy. All rights reserved.
//

import UIKit

class ModeViewController: UIViewController {

    @IBOutlet weak var pinType: UISwitch!
    @IBAction func createMode(_ sender: UIButton) {
    pin(.create)
  }
  
  @IBAction func changeMode(_ sender: UIButton) {
    pin(.change)
  }
  
  @IBAction func deactiveMode(_ sender: UIButton) {
    pin(.deactive)
  }
  
  @IBAction func validateMode(_ sender: UIButton) {
    pin(.validate)
  }
  
  func pin(_ mode: ALMode) {
    
    var appearance = ALAppearance()
    appearance.image = UIImage(named: "face")!
    appearance.title = "Devios Ryasnoy"
    appearance.isSensorsEnabled = true
    appearance.pincodeType = pinType.isOn ? .alphanumeric : .numeric
    appearance.backgroundColor = .white
    appearance.foregroundColor = .black
    appearance.hightlightColor = .blue
    AppLocker.present(with: mode, and: appearance)
  }

}


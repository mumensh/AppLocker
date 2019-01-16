//
//  AppALConstants.swift
//  AppLocker
//
//  Created by Oleg Ryasnoy on 07.07.17.
//  Copyright © 2017 Oleg Ryasnoy. All rights reserved.
//

import UIKit
import AudioToolbox
import LocalAuthentication
import Valet

internal enum ALConstants {
  static let kPincode = "pincode" // Key for saving pincode to keychain
  static let kLocalizedReason = "Unlock with sensor" // Your message when sensors must be shown
  static let duration = 0.3 // Duration of indicator filling
  static let maxPinLength = 4
  
  enum button: Int {
    case delete = 1000
    case cancel = 1001
  }
    
  static func getNibName(forType type: PinCodeType) -> String {
    switch type {
    case .numeric:
      return "AppLocker"
    case .alphanumeric:
      return "AppLocker-Alphanumeric"
    }
  }
}

public enum PinCodeType {
  case numeric
  case alphanumeric
}

public struct ALAppearance { // The structure used to display the controller
  public var title: String?
  public var subtitle: String?
  public var image: UIImage?
  public var backgroundColor: UIColor?
  public var foregroundColor: UIColor?
  public var hightlightColor: UIColor?
  public var isSensorsEnabled: Bool?
  public var pincodeType: PinCodeType = .numeric
  public init() {}
}

public enum ALMode { // Modes for AppLocker
  case validate
  case change
  case deactive
  case create
}

public class AppLocker: UIViewController {
  
  // MARK: - Top view
  @IBOutlet weak var photoImageView: UIImageView!
  @IBOutlet weak var messageLabel: UILabel!
  @IBOutlet weak var submessageLabel: UILabel!
  @IBOutlet var pinIndicators: [Indicator]!
  @IBOutlet var pinNumbers: [RoundedButton]!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var deleteButton: UIButton!

  static let valet = Valet.valet(with: Identifier(nonEmpty: "Druidia")!, accessibility: .whenUnlockedThisDeviceOnly)  
  // MARK: - Pincode
  private let context = LAContext()
  private var pin = "" // Entered pincode
  private var reservedPin = "" // Reserve pincode for confirm
  private var isFirstCreationStep = true
  private static var sensorCanceled = false
  private var pinCodeType: PinCodeType = .numeric
  fileprivate static var savedPin: String? {
    get {
      return AppLocker.valet.string(forKey: ALConstants.kPincode)
    }
    set {
      guard let newValue = newValue else { return }
      AppLocker.valet.set(string: newValue, forKey: ALConstants.kPincode)
    }
  }
  
  fileprivate var mode: ALMode? {
    didSet {
      let mode = self.mode ?? .validate
      switch mode {
      case .create:
        submessageLabel.text = "Create your passcode" // Your submessage for create mode
      case .change:
        submessageLabel.text = "Enter your passcode" // Your submessage for change mode
      case .deactive:
        submessageLabel.text = "Enter your passcode" // Your submessage for deactive mode
      case .validate:
        submessageLabel.text = "Enter your passcode" // Your submessage for validate mode
        cancelButton.isHidden = true
        isFirstCreationStep = false
      }
    }
  }
    
  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
        
    if pinCodeType == .alphanumeric {
      let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
      self.view.addGestureRecognizer(tapGesture)
      self.view.isUserInteractionEnabled = true
      self.becomeFirstResponder()
    }
  }
    
  public override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.view.gestureRecognizers?.forEach(self.view.removeGestureRecognizer)
  }
    
  @objc fileprivate func onTap() {
    if pinCodeType == .alphanumeric {
      self.becomeFirstResponder()
    }
  }
  
  private func precreateSettings () { // Precreate settings for change mode
    mode = .create
    clearView()
  }
  
  private func drawing(isNeedClear: Bool, tag: String? = nil) { // Fill or cancel fill for indicators
    let results = pinIndicators.filter { $0.isNeedClear == isNeedClear }
    let pinView = isNeedClear ? results.last : results.first
    pinView?.isNeedClear = !isNeedClear
    
    UIView.animate(withDuration: ALConstants.duration, animations: {
      pinView?.backgroundColor = isNeedClear ? .clear : pinView?.highlightedBackgroundColor
    }) { _ in
      isNeedClear ? self.pin = String(self.pin.dropLast()) : self.pincodeChecker(tag ?? "0")
    }
  }
  
  private func pincodeChecker(_ pinNumber: String) {
    if pin.count < ALConstants.maxPinLength {
      pin.append(pinNumber)
      if pin.count == ALConstants.maxPinLength {
        switch mode ?? .validate {
        case .create:
          createModeAction()
        case .change:
          changeModeAction()
        case .deactive:
          deactiveModeAction()
        case .validate:
          validateModeAction()
        }
      }
    }
  }
  
  // MARK: - Modes
  private func createModeAction() {
    if isFirstCreationStep {
      isFirstCreationStep = false
      reservedPin = pin
      clearView()
      submessageLabel.text = "Confirm your pincode"
    } else {
      confirmPin()
    }
  }
  
  private func changeModeAction() {
    pin == AppLocker.savedPin ? precreateSettings() : incorrectPinAnimation()
  }
  
  private func deactiveModeAction() {
    pin == AppLocker.savedPin ? removePin() : incorrectPinAnimation()
  }
  
  private func validateModeAction() {
    pin == AppLocker.savedPin ? dismiss(animated: true, completion: nil) : incorrectPinAnimation()
  }
  
  private func removePin() {
    AppLocker.removePinFromValet()
    dismiss(animated: true, completion: nil)
  }
    
  private static func removePinFromValet() {
    AppLocker.valet.removeObject(forKey: ALConstants.kPincode)
  }
  
  private func confirmPin() {
    if pin == reservedPin {
      AppLocker.savedPin = pin
      dismiss(animated: true, completion: nil)
    } else {
      incorrectPinAnimation()
    }
  }
  
  private func incorrectPinAnimation() {
    pinIndicators.forEach { view in
      view.shake(delegate: self)
      view.backgroundColor = .clear
    }
    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
  }
  
  fileprivate func clearView() {
    pin = ""
    pinIndicators.forEach { view in
      view.isNeedClear = false
      UIView.animate(withDuration: ALConstants.duration, animations: {
        view.backgroundColor = .clear
      })
    }
  }
  
  // MARK: - Touch ID / Face ID
  fileprivate func checkSensors() {
    guard mode == .validate else {return}
    
    var policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics // iOS 8+ users with Biometric and Custom (Fallback button) verification
    
    // Depending the iOS version we'll need to choose the policy we are able to use
    if #available(iOS 9.0, *) {
      // iOS 9+ users with Biometric and Passcode verification
      policy = .deviceOwnerAuthentication
    }
    
    var err: NSError?
    // Check if the user is able to use the policy we've selected previously
    guard context.canEvaluatePolicy(policy, error: &err) else {return}
    
    // The user is able to use his/her Touch ID / Face ID 👍
    context.evaluatePolicy(policy, localizedReason: ALConstants.kLocalizedReason, reply: {  success, error in
      DispatchQueue.main.async {
        if success {
          self.dismiss(animated: true, completion: nil)
        } else if let error = error, error._code != LAError.authenticationFailed.rawValue {
          AppLocker.sensorCanceled = true
        }
      }
    })
  }
  
  // MARK: - Keyboard
  @IBAction func keyboardPressed(_ sender: UIButton) {
    switch sender.tag {
    case ALConstants.button.delete.rawValue:
      drawing(isNeedClear: true)
    case ALConstants.button.cancel.rawValue:
      clearView()
      dismiss(animated: true, completion: nil)
    default:
      drawing(isNeedClear: false, tag: "\(sender.tag)")
    }
  }
  
}

// MARK: - CAAnimationDelegate
extension AppLocker: CAAnimationDelegate {
  public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    clearView()
  }
}

extension AppLocker: UIKeyInput {
  public var hasText: Bool {
    return self.pin.count > 0
  }
    
  public func insertText(_ text: String) {
    if text == "\n" { self.resignFirstResponder(); return }
    drawing(isNeedClear: false, tag: text)
  }
    
  public func deleteBackward() {
    drawing(isNeedClear: true)
  }
    
  public override var canBecomeFirstResponder: Bool { return pinCodeType == .alphanumeric }
    
  public var autocorrectionType: UITextAutocorrectionType { get { return .no } set { assertionFailure() } }
  public var keyboardType: UIKeyboardType { get { return .namePhonePad } set { assertionFailure() } }
}

// MARK: - Present
public extension AppLocker {
  // Present AppLocker
  class func present(with mode: ALMode, and config: ALAppearance? = nil) {
    //Check if AppLocker viewController is in the stack of viewControllers, if it's, do not present it again
    if var topController = UIApplication.shared.keyWindow?.rootViewController {
      var shouldReturn = false
      while let presentedViewController = topController.presentedViewController {
        if presentedViewController.isKind(of: AppLocker.self) { shouldReturn = true; break }
          topController = presentedViewController
        }
      if shouldReturn { return }
    }
    
    //Determine if saved pin is Alphanumeric or Numeric
    var pinType: PinCodeType = config?.pincodeType ?? .numeric
    if let savedPin = AppLocker.savedPin, savedPin.count > 0, savedPin.rangeOfCharacter(from: CharacterSet.letters) != nil {
      pinType = .alphanumeric
    }
    //Check if AppLocker view controller can be initiated
    guard let root = UIApplication.shared.keyWindow?.rootViewController,
          let locker = Bundle(for: self.classForCoder()).loadNibNamed(ALConstants.getNibName(forType: pinType), owner: self, options: nil)?.first as? AppLocker else {
        return
    }
    AppLocker.sensorCanceled = false
    locker.pinCodeType = pinType
    locker.messageLabel.text = config?.title ?? ""
    locker.messageLabel.textColor = config?.foregroundColor ?? .black
    locker.submessageLabel.text = config?.subtitle ?? ""
    locker.submessageLabel.textColor = config?.foregroundColor ?? .black
    locker.view.backgroundColor = config?.backgroundColor ?? .white
    locker.pinIndicators.forEach({ $0.highlightedBackgroundColor = config?.hightlightColor })
    locker.cancelButton.setTitleColor(config?.foregroundColor ?? .black, for: .normal)
    locker.mode = mode
    
    if pinType == .numeric {
      locker.pinNumbers.forEach({ $0.setTitleColor(config?.foregroundColor ?? .black, for: .normal); $0.setTitleColor(config?.hightlightColor ?? .white, for: .highlighted); $0.setBackgroundColor(color: config?.hightlightColor ?? .white, forState: .highlighted) })
      locker.deleteButton.setTitleColor(config?.foregroundColor ?? .black, for: .normal)
    }
    
    if config?.isSensorsEnabled ?? false && !AppLocker.sensorCanceled {
      locker.checkSensors()
    }
    
    if let image = config?.image {
      locker.photoImageView.image = image
    } else {
      locker.photoImageView.isHidden = true
    }
    
    if let presentedViewController = root.presentedViewController {
        presentedViewController.present(locker, animated: true, completion: nil)
    } else {
        root.present(locker, animated: true, completion: nil)
    }
  }
    
  class func hasPinCode() -> Bool {
    return AppLocker.valet.containsObject(forKey: ALConstants.kPincode)
  }
    
  class func deletePinCode() {
    AppLocker.removePinFromValet()
  }
}

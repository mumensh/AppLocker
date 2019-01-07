//
//  View.swift
//  PasscodeLock
//
//  Created by Oleg Ryasnoy on 18.04.17.
//  Copyright © 2017 Oleg Ryasnoy. All rights reserved.
//

import UIKit

class Indicator: UIView {
    var isNeedClear = false
    var highlightedBackgroundColor: UIColor? = .white
}

class RoundedButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        round()
    }
    
    /// Sets the background color to use for the specified button state.
    func setBackgroundColor(color: UIColor, forState: UIControlState) {
        let minimumSize: CGSize = CGSize(width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(minimumSize)
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            context.fill(CGRect(origin: .zero, size: minimumSize))
        }
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.clipsToBounds = true
        self.setBackgroundImage(colorImage, for: forState)
    }
}

let kRoundKey = "kRoundKey"

protocol Roundable {
    func round()
}

extension Roundable where Self: UIView {
    func round() {
        guard self.accessibilityHint == kRoundKey else {return}
        layer.cornerRadius = frame.height/2
        layer.borderWidth = 1
        layer.borderColor = UIColor.lightGray.cgColor
    }
}

extension UIView: Roundable {
    open override var accessibilityHint: String? {
        didSet {
            round()
        }
    }
}

extension UIView {
    func shake(delegate: CAAnimationDelegate) {
        let animationKeyPath = "transform.translation.x"
        let shakeAnimation = "shake"
        let duration = 0.6
        let animation = CAKeyframeAnimation(keyPath: animationKeyPath)
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.duration = duration
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        animation.delegate = delegate
        layer.add(animation, forKey: shakeAnimation)
    }
}


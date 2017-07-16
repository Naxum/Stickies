//
//  UIViewExtensions.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/16/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import UIKit

@IBDesignable extension UIView {
	@IBInspectable var cornerRadius: CGFloat {
		set {
			layer.cornerRadius = newValue
		}
		get {
			return layer.cornerRadius
		}
	}
}

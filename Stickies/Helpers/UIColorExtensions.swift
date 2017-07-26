//
//  UIColorExtensions.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/25/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import UIKit
import GLKit

extension UIColor {
	var rgba:(r:CGFloat, g:CGFloat, b:CGFloat, a:CGFloat) {
		var r:CGFloat = 0
		var g:CGFloat = 0
		var b:CGFloat = 0
		var a:CGFloat = 0
		self.getRed(&r, green: &g, blue: &b, alpha: &a)
		return (r, g, b, a)
	}
	
	var vector4:GLKVector4 {
		let (r, g, b, a) = self.rgba
		return GLKVector4Make(Float(r), Float(g), Float(b), Float(a))
	}
}

//
//  CGPointExtensions.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/11/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGFloat {
	func lerp(to other:CGFloat, by percent:CGFloat) -> CGFloat {
		return self + (other - self) * percent
	}
}

extension CGPoint {
    init(xy: CGFloat) {
        x = xy
        y = xy
    }
	
	init (x: CGFloat) {
		self.x = x
		y = 0
	}
	
	init (y: CGFloat) {
		x = 0
		self.y = y
	}
	
	func lerp(to other:CGPoint, by percent:CGFloat) -> CGPoint {
		return CGPoint(x: self.x.lerp(to: other.x, by: percent), y: self.y.lerp(to: other.y, by: percent))
	}
    
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
	
	static func - (left: CGPoint, right: CGPoint) -> CGPoint {
		return CGPoint(x: left.x - right.x, y: left.y - right.y)
	}
    
    static func * (left: CGPoint, right: CGFloat) -> CGPoint {
        return CGPoint(x: left.x * right, y: left.y * right)
    }
	
	static func / (left: CGPoint, right: CGFloat) -> CGPoint {
		return CGPoint(x: left.x / right, y: left.y / right)
	}
}

extension CGSize {
	init (ratio:CGFloat) {
		width = ratio
		height = ratio
	}
	
	static func + (left:CGSize, right:CGSize) -> CGSize {
		return CGSize(width: left.width + right.width, height: left.height + right.height)
	}
}

extension CGRect {
	var center:CGPoint { return CGPoint(x: midX, y: midY) }
}

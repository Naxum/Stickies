//
//  TouchSmoother.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/23/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import UIKit
import GLKit

class TouchSmoother {
	fileprivate var lastMidpoint:CGPoint?
	fileprivate var paths = [UIBezierPath]()
	
	var smoothedPoints:[GLKVector2] {
		var result = [GLKVector2]()
		
		for path in paths {
			let dashed = path.cgPath.copy(dashingWithPhase: 0, lengths: [0.25, 0.25])
			let points = dashed.points
			for point in points {
				result.append(GLKVector2Make(Float(point.x), Float(point.y)))
			}
		}
		
		return result
	}
	
	func handle(touch:UITouch, in view:UIView) {
		let path = UIBezierPath()
		
		let currentPos = touch.preciseLocation(in: view)
		let previousPos = touch.precisePreviousLocation(in: view)
		let midpoint = currentPos.lerp(to: previousPos, by: 0.5)
		
		if lastMidpoint != nil {
			path.move(to: lastMidpoint!)
		} else {
			path.move(to: currentPos)
		}
		
		if touch.phase == .ended {
			if lastMidpoint != nil {
				path.addLine(to: currentPos)
			}
			path.close()
		} else if touch.phase == .moved {
			path.addQuadCurve(to: midpoint, controlPoint: previousPos)
		}
		
		lastMidpoint = midpoint
		paths.append(path)
	}
	
	func reset() {
		paths.removeAll()
		lastMidpoint = nil
	}
}

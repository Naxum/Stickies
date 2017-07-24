//
//  CGPathExtensions.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/23/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import UIKit

extension CGPath {
	var points:[CGPoint] {
		var result = [CGPoint]()
		self.applyWithBlock { element in
			switch element.pointee.type {
			case .addLineToPoint:
				result.append(element.pointee.points[0])
			case .addQuadCurveToPoint:
				result.append(element.pointee.points[1])
			case .addCurveToPoint:
				result.append(element.pointee.points[2])
			case .moveToPoint: fallthrough
			case .closeSubpath:
				break
			}
		}
		return result
	}
}

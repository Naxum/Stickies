//
//  CGPointExtensions.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/11/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGPoint {
    init(xy: CGFloat) {
        x = xy
        y = xy
    }
    
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
    
    static func * (left: CGPoint, right: CGFloat) -> CGPoint {
        return CGPoint(x: left.x * right, y: left.y * right)
    }
}

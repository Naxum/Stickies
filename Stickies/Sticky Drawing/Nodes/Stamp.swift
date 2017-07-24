//
//  Stamp.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/23/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import Foundation
import GLKit

struct Stamp {
	let matrix:GLKMatrix4
	let color:GLKVector4
	
	init(x:Float, y:Float, white:Bool, alpha:Float = 1, width:Float = 10, height:Float = 10, rotation:Float = 0) {
		let size = DrawingSettings.canvasSize
		let halfSize = size / 2
		let position = GLKVector3Make((x - halfSize) / halfSize, (y - halfSize) / halfSize, 0)
		let scale = GLKVector3Make(width / size, height / size, 1)
		
		var m = GLKMatrix4Identity
		m = GLKMatrix4TranslateWithVector3(m, position)
		m = GLKMatrix4RotateZ(m, rotation)
		m = GLKMatrix4ScaleWithVector3(m, scale)
		matrix = m
		
		let brightness = Float(white ? 1 : 0)
		color = GLKVector4Make(brightness, brightness, brightness, alpha)
	}
}

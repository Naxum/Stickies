//
//  MTLTextureExtensions.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/25/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import MetalKit

extension MTLTexture {
	var region:MTLRegion { return MTLRegion(origin: MTLOrigin(), size: MTLSize(width: width, height: height, depth: depth)) }
}

//
//  Quad.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/23/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import Foundation
import GLKit

struct Quad {
	let vertices = [
		Vertex(x: -1, y:  1, z: 0, u: 0, v: 1),
		Vertex(x: -1, y: -1, z: 0, u: 0, v: 0),
		Vertex(x:  1, y: -1, z: 0, u: 1, v: 0),
		Vertex(x:  1, y: -1, z: 0, u: 1, v: 0),
		Vertex(x:  1, y:  1, z: 0, u: 1, v: 1),
		Vertex(x: -1, y:  1, z: 0, u: 0, v: 1)
	]
}

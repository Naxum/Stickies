//
//  DrawingControllerSegue.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/22/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import UIKit

class DrawingControllerSegue: UIStoryboardSegue {
	static let identifier = "DrawingSegue"
	
	override func perform() {
		print("Performing segue...")
		source.present(destination, animated: false) {
			print("Segue complete")
		}
	}
}

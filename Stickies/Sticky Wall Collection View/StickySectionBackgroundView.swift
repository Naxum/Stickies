//
//  StickySectionBackgroundView.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/15/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import UIKit

class StickySectionBackgroundView: UICollectionReusableView {
	static let identifier = "stickyBackground"
	
	override var reuseIdentifier: String? { return StickySectionBackgroundView.identifier }
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		initialize()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initialize()
	}
	
	func initialize() {
		backgroundColor = UIColor(hue: 0, saturation: 0, brightness: 0.9, alpha: 1)
		layer.cornerRadius = 8
		layer.zPosition = -1
		isUserInteractionEnabled = false
	}
}

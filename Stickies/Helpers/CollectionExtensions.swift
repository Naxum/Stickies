//
//  CollectionExtensions.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/22/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import Foundation

extension RandomAccessCollection {
	func random() -> Self.Element {
		return self[index(startIndex, offsetBy: numericCast(arc4random_uniform(UInt32(self.count.magnitude))))]
	}
}

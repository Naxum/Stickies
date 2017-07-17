//
//  StickyModelExtensions.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/16/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import CoreData

extension StickyBoard {
	var activeSections:Set<StickySection> { return (sections as! Set<StickySection>).filter { !$0.isTrashSection } }
}

extension StickySection {
	var activeStickies:Set<StickyNote> { return (stickies as! Set<StickyNote>).filter { !$0.removed } }
	var allStickies:Set<StickyNote> { return stickies as! Set<StickyNote> }
	
	func refreshStickyIndexes() {
		let xValues = Set<Int64>(activeStickies.map({ $0.localX })).sorted()
		let yValues = Set<Int64>(activeStickies.map({ $0.localY })).sorted()
		
		var currentIndex:Int64 = 0
		
		for x in xValues {
			for y in yValues {
				guard let stickyNote = activeStickies.first(where: {$0.localX == x && $0.localY == y}) else { continue }
				stickyNote.index = currentIndex
				currentIndex += 1
			}
		}
	}
}

extension StickyNote {
	var indexPath:IndexPath { return IndexPath(item: Int(index), section: Int(section!.index)) }
}

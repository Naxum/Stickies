//
//  StickyModelExtensions.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/16/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import CoreData
import CoreGraphics

extension StickyBoard {
	var activeSections:Set<StickySection> { return (sections as! Set<StickySection>).filter { !$0.isTrashSection } }
	
	func getSectionFrame(sectionIndex:Int, withContentHeight height:CGFloat) throws -> CGRect {
		guard let section = activeSections.first(where: {$0.index == sectionIndex}) else {
			throw StickyBoardError.SectionIndexOutOfRange
		}
		return try getSectionFrame(section: section, withContentHeight: height)
	}
	
	func getSectionFrame(section:StickySection, withContentHeight height:CGFloat) throws -> CGRect {
		var boardWidth:CGFloat = 0
		let boardPadding = StickyGridSettings.boardPadding
		for index in 0...section.index {
			guard let currentSection = activeSections.first(where: {$0.index == index }) else {
				print("Could not find section at \(index) - major issue!")
				throw StickyBoardError.SectionNotInBoard
			}
			let sectionOuterWidth = section.getInnerWidth(withContentHeight: height) + (StickyGridSettings.sectionPadding * 2)
			if section == currentSection {
				return CGRect(x: boardWidth + boardPadding, y: boardPadding, width: sectionOuterWidth, height: height - (boardPadding * 2))
			}
			boardWidth += sectionOuterWidth + StickyGridSettings.sectionOffsetSpacing
		}
		
		throw StickyBoardError.SectionNotInBoard
	}
	
	func getBoardFrame(withContentHeight height:CGFloat) -> CGRect {
		var boardWidth:CGFloat = StickyGridSettings.boardPadding * 2
		for section in activeSections.sorted(by: {$0.index < $1.index}) {
			boardWidth += section.getInnerWidth(withContentHeight: height) + (StickyGridSettings.sectionPadding * 2)
		}
		boardWidth += StickyGridSettings.sectionOffsetSpacing * CGFloat(activeSections.count - 1)
		return CGRect(origin: CGPoint(), size: CGSize(width: boardWidth, height: height))
	}
	
	enum StickyBoardError: Error {
		case SectionNotInBoard
		case SectionIndexOutOfRange
	}
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
	
	func refreshMaxGridX() {
		maxGridX = activeStickies.map({$0.localX}).max()!
	}
	
	func getInnerWidth(withContentHeight height:CGFloat) -> CGFloat {
		let maxX = CGFloat(maxGridX)
		let stickySize = StickyGridSettings.getStickySize(forContentHeight: height)
		return ((maxX / StickyGridSettings.gridCellsPerStickySize) * stickySize) + (StickyGridSettings.gridSpacing * maxX) + (stickySize / 2)
	}
}

extension StickyNote {
	var indexPath:IndexPath { return IndexPath(item: Int(index), section: Int(section!.index)) }
	var gridPosition:StickyGridPosition { return StickyGridPosition(x: Int(localX), y: Int(localY), section: Int(section!.index)) }
}

//
//  StickyGridSettings.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/15/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import UIKit

/// class with layout helpers and settings
class StickyGridSettings {
	
	///	divisor to get grid size. IE: gridSize = stickySize / gridCellsPerStickySize
	static let gridCellsPerStickySize:CGFloat = 2
	
	/// how many rows can vertically fit into this system
	static let gridRows:CGFloat = 8
	
	/// padding applied to all grid positions
	static let boardPadding:CGFloat = 16
	static let sectionPadding:CGFloat = 24
	
	/// interal spacing between grid cells inside a section
	static let gridSpacing:CGFloat = 24
	
	/// spacing between sections
	static let sectionOffsetSpacing:CGFloat = 32
	
	/// returns the square size of a sticky note for UICollectionViewLayoutAttributes.size, based on a view's bounds' height
	static func getStickySize(forContentHeight height:CGFloat) -> CGFloat {
		let padding = (boardPadding * 2) + (sectionPadding * 2) //tops and bottoms
		let maxSpacingY = gridSpacing * (gridRows / gridCellsPerStickySize)
		return (height - padding - maxSpacingY) / (gridRows / gridCellsPerStickySize)
	}
}

struct StickyGridPosition {
	let gridPosX:Int
	let gridPosY:Int
	let sectionIndex:Int
	
	init(x:Int, y:Int, section:Int) {
		gridPosX = x
		gridPosY = y
		sectionIndex = section
	}
	
	var cgPoint:CGPoint { return CGPoint(x: CGFloat(gridPosX), y: CGFloat(gridPosY ))}
	
	func getFrame(withContentHeight height:CGFloat) -> CGRect {
		let stickySize = StickyGridSettings.getStickySize(forContentHeight: height)
		let sectionBounds = try! StickyHelper.currentBoard.getSectionFrame(sectionIndex: sectionIndex, withContentHeight: height)
		let sectionOffset = CGPoint(x: sectionBounds.minX + StickyGridSettings.sectionPadding, y: sectionBounds.minY + StickyGridSettings.sectionPadding)
		let inbetweenSpacing = (cgPoint / StickyGridSettings.gridCellsPerStickySize) * StickyGridSettings.gridSpacing
		let stickySpacing = (cgPoint / StickyGridSettings.gridCellsPerStickySize) * stickySize
		return CGRect(origin: sectionOffset + inbetweenSpacing + stickySpacing, size: CGSize(ratio: stickySize))
		
	}
	
	static func == (left:StickyGridPosition, right:StickyGridPosition) -> Bool {
		return left.gridPosX == right.gridPosX && left.gridPosY == right.gridPosY
	}
}

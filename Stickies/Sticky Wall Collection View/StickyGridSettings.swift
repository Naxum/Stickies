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
	static let boardPadding:CGFloat = 8
	static let sectionPadding:CGFloat = 16
	
	/// interal spacing between grid cells inside a section
	static let gridSpacing:CGFloat = 8
	
	/// spacing between sections
	static let sectionOffsetSpacing:CGFloat = 32
	
	/// returns the square size of a sticky note for UICollectionViewLayoutAttributes.size, based on a view's bounds' height
	static func getStickySize(forContentHeight height:CGFloat) -> CGFloat {
		let padding = (boardPadding * 2) + (sectionPadding * 2) //tops and bottoms
		let maxSpacingY = gridSpacing * (gridRows / gridCellsPerStickySize)
		return (height - padding - maxSpacingY) / (gridRows / gridCellsPerStickySize)
	}
	
	/// returns internal offset for a grid position, without external offsets (previous sections' widths and offsets)
	static func getStickyOffsetInSection(for position:StickyGridPosition, with stickySize:CGFloat) -> CGPoint {
//		let padding = CGPoint(xy: boardPadding + sectionPadding)
		let padding = CGPoint(xy: sectionPadding)
		let inbetweenSpacing = (position.cgPoint / gridCellsPerStickySize) * gridSpacing
		let stickySpacing = (position.cgPoint / gridCellsPerStickySize) * stickySize
		return padding + inbetweenSpacing + stickySpacing
	}
}

struct StickyGridPosition {
	let gridPosX:Int
	let gridPosY:Int
	
	init(x:Int, y:Int) {
		gridPosX = x
		gridPosY = y
	}
	
	var cgPoint:CGPoint { return CGPoint(x: CGFloat(gridPosX), y: CGFloat(gridPosY ))}
	
	func getStickyPlacement(forStickySize stickySize:CGFloat) -> (origin:CGPoint, center:CGPoint, size:CGSize) {
		let offset = StickyGridSettings.getStickyOffsetInSection(for: self, with: stickySize)
		let center = offset + CGPoint(xy: stickySize / StickyGridSettings.gridCellsPerStickySize)
		let size = CGSize(width: stickySize, height: stickySize)
		return (offset, center, size)
	}
}

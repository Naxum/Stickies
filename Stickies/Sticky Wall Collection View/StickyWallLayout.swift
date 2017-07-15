//
//  StickyWallLayout.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/10/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import UIKit
import CoreData

class StickyWallLayout: UICollectionViewLayout {
    override class var layoutAttributesClass:AnyClass { return StickyWallLayoutAttributes.self }
    
    var attributesList = [UICollectionViewLayoutAttributes]()
	
    override var collectionViewContentSize: CGSize {
        let height = collectionView!.bounds.height //height should always be the same
		let stickySize = StickyGridSettings.getStickySize(forContentHeight: height)
		var boardBounds = CGRect(origin: CGPoint(xy: 0), size: CGSize(width: 0, height: height))
		let sectionPadding = StickyGridSettings.sectionPadding
		let boardPadding = StickyGridSettings.boardPadding
		
        for sectionIndex in 0..<collectionView!.numberOfSections {
			let sectionOffset = StickyGridSettings.sectionOffsetSpacing * CGFloat(sectionIndex) + boardBounds.width
			var sectionBounds = CGRect(x: boardPadding + sectionOffset, y: boardPadding + sectionPadding, width: 0, height: 0)
            for itemIndex in 0..<collectionView!.numberOfItems(inSection: sectionIndex) {
				guard let attributes = layoutAttributesForItem(at: IndexPath(item: itemIndex, section: sectionIndex)) as? StickyWallLayoutAttributes else {
					continue
				}
				
				let (origin, _, size) = attributes.position.getStickyPlacement(forStickySize: stickySize)
				let stickyRect = CGRect(origin: origin + sectionBounds.origin, size: size)
				sectionBounds = sectionBounds.union(stickyRect)
            }
			sectionBounds = sectionBounds.union(CGRect(x: sectionBounds.maxX, y: sectionBounds.maxY, width: sectionPadding, height: sectionPadding))
            boardBounds = boardBounds.union(sectionBounds)
        }
		
		boardBounds = boardBounds.union(CGRect(x: boardBounds.maxX, y: boardBounds.maxY, width: boardPadding, height: 0))
		
		print("boardBoundsHeight - height: \(boardBounds.height - height)")
		
        return boardBounds.size
    }
    
    override func prepare() {
        super.prepare()
		
		// we're recreating the attributes list, so clear any existing attributes
		attributesList.removeAll()
		
		let collectionViewContentHeight = collectionViewContentSize.height
		let stickySize = StickyGridSettings.getStickySize(forContentHeight: collectionViewContentHeight)
		let sectionPadding = StickyGridSettings.sectionPadding
		let boardPadding = StickyGridSettings.boardPadding
		var boardBounds = CGRect(origin: CGPoint(xy: 0), size: CGSize(width: 0, height: collectionViewContentHeight))
		
		// loop through all sections and sticky notes within the current board
        for sectionIndex in 0..<collectionView!.numberOfSections {
			
			// section data (contains sticky notes, which contain their position data)
			let section = StickyHelper.currentBoard.stickySections.first(where: { $0.index == sectionIndex })!
			
			// section offset based on how many sections have existed so far
			let sectionOffset = StickyGridSettings.sectionOffsetSpacing * CGFloat(sectionIndex) + boardBounds.width
			
			var sectionBounds = CGRect(x: boardPadding + sectionOffset, y: boardPadding, width: 0, height: 0)
			
			// loop through each itemIndex and corresponding sticky note
            for itemIndex in 0..<collectionView!.numberOfItems(inSection: sectionIndex) {
                let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
				guard let stickyNote = section.stickyNotes.first(where: { $0.index == itemIndex }) else {
					print("Sticky note is nil! \(indexPath) section: \(section.stickyNotes)")
					continue
				}
				
				// sticky notes save their grid positions in core data, which allows us to position them correctly
				// otherwise we would just use a normal flow layout if we couldn't position them relative to their section
				let gridPosX = Int(stickyNote.localX)
				let gridPosY = Int(stickyNote.localY)
				
				// attributes contains all information needed to display a cell's view, without needing to create the cell itself
                let cellAttributes = StickyWallLayoutAttributes(forCellWith: indexPath)
				
				// grid position (custom property)
                cellAttributes.position = StickyGridPosition(x: gridPosX, y: gridPosY)
				
				// view size and center are UIKit properties
				let (origin, center, size) = cellAttributes.position.getStickyPlacement(forStickySize: stickySize)
                cellAttributes.size = size
				cellAttributes.center = center + sectionBounds.origin
				
				let stickyRect = CGRect(origin: origin + sectionBounds.origin, size: size)
				sectionBounds = sectionBounds.union(stickyRect)
				
                attributesList.append(cellAttributes)
            }
			
			// add final section padding, giving us spacing between the last cells and the edges of the section
			sectionBounds = sectionBounds.union(CGRect(x: sectionBounds.maxX, y: sectionBounds.maxY, width: sectionPadding, height: sectionPadding))
			
			// create section background attributes (just need size and center)
			let sectionIndexPath = IndexPath(index: sectionIndex)
			print("Section index path: \(sectionIndexPath)")
			let sectionAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: StickySectionBackgroundView.identifier, with: sectionIndexPath)
			
			// cover the entire width and height of the section, position in the center
			sectionAttributes.size = sectionBounds.size
			sectionAttributes.center = CGPoint(x: sectionBounds.midX, y: sectionBounds.midY)
			attributesList.append(sectionAttributes)
			
            boardBounds = boardBounds.union(sectionBounds)
        }
		
		boardBounds = boardBounds.union(CGRect(x: boardBounds.maxX, y: boardBounds.maxY, width: boardPadding, height: 0))
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return attributesList
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return attributesList.first { $0.indexPath == indexPath }
    }
	
	override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		return attributesList.first { $0.indexPath == indexPath }
	}
}

class StickyWallLayoutAttributes: UICollectionViewLayoutAttributes {
	var position:StickyGridPosition!
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let copiedAttributes: StickyWallLayoutAttributes = super.copy(with: zone) as! StickyWallLayoutAttributes
        copiedAttributes.position = self.position
        return copiedAttributes
    }
}

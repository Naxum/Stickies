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
        return StickyHelper.currentBoard.getBoardFrame(withContentHeight: height).size
    }
    
    override func prepare() {
        super.prepare()
		
		// we're recreating the attributes list, so clear any existing attributes
		attributesList.removeAll()
		
		let height = collectionViewContentSize.height
		
		// loop through all sections and sticky notes within the current board
        for sectionIndex in 0..<collectionView!.numberOfSections {
			
			// section data (contains sticky notes, which contain their position data)
			let section = StickyHelper.currentBoard.activeSections.first(where: { $0.index == sectionIndex })!
			
			// loop through each itemIndex and corresponding sticky note
            for itemIndex in 0..<collectionView!.numberOfItems(inSection: sectionIndex) {
                let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
				guard let stickyNote = section.activeStickies.first(where: { $0.index == itemIndex }) else {
					print("Sticky note is nil! \(indexPath) section: \(section.activeStickies)")
					continue
				}

				// attributes contains all information needed to display a cell's view, without needing to create the cell itself
				let cellPos = stickyNote.gridPosition
				let cellFrame = cellPos.getFrame(withContentHeight: height)
                let cellAttributes = StickyWallLayoutAttributes(forCellWith: indexPath)
				
				// view size and center are UIKit properties
                cellAttributes.size = cellFrame.size
				cellAttributes.center = cellFrame.center
				
                attributesList.append(cellAttributes)
            }
			
			// create section background attributes (just need size and center)
			let sectionIndexPath = IndexPath(index: sectionIndex)
			let sectionAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: StickySectionBackgroundView.identifier, with: sectionIndexPath)
			
			// cover the entire width and height of the section, position in the center
			let sectionFrame = try! StickyHelper.currentBoard.getSectionFrame(sectionIndex: sectionIndex, withContentHeight: height)
			sectionAttributes.size = sectionFrame.size
			sectionAttributes.center = sectionFrame.center
			attributesList.append(sectionAttributes)
        }
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
//	var position:StickyGridPosition!
	
//    override func copy(with zone: NSZone? = nil) -> Any {
//        let copiedAttributes: StickyWallLayoutAttributes = super.copy(with: zone) as! StickyWallLayoutAttributes
//        copiedAttributes.position = self.position
//        return copiedAttributes
//    }
}

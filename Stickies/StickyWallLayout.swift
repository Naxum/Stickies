//
//  StickyWallLayout.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/10/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import UIKit

class StickyWallLayout: UICollectionViewLayout {
    let gridPadding:CGFloat = 8.0
    let gridRows:CGFloat = 4.0
    
    var gridSize:CGFloat {
        return (collectionView!.bounds.height / gridRows) - (gridRows * gridPadding)
    }
    
    override class var layoutAttributesClass:AnyClass { return StickyWallLayoutAttributes.self }
    
    override var collectionViewContentSize: CGSize {
        var gridWidth:CGFloat = 0.0
        let height = collectionView!.bounds.height //height should always be the same
        
        for sectionIndex in 0..<collectionView!.numberOfSections {
            var bounds = StickyGridBounds()
            for itemIndex in 0..<collectionView!.numberOfItems(inSection: sectionIndex) {
                let stickyCell = collectionView!.cellForItem(at: IndexPath(item: itemIndex, section: sectionIndex)) as! StickyCell
                bounds.encapsulate(position: stickyCell.position)
            }
            gridWidth += bounds.toCGSize().width
        }
        
        return CGSize(width: gridWidth * gridSize, height: height)
    }
    
    override func prepare() {
        super.prepare()
        
        //TODO: Prepare layout
    }
}

class StickyWallLayoutAttributes: UICollectionViewLayoutAttributes {
    var position = StickyGridPosition(x: 0, y: 0)
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let copiedAttributes: StickyWallLayoutAttributes = super.copy(with: zone) as! StickyWallLayoutAttributes
        copiedAttributes.position = self.position
        return copiedAttributes
    }
}

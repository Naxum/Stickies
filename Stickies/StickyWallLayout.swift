//
//  StickyWallLayout.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/10/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import UIKit

fileprivate let gridRows:CGFloat = 4.0

class StickyWallLayout: UICollectionViewLayout {
    override class var layoutAttributesClass:AnyClass { return StickyWallLayoutAttributes.self }
    
    let gridPadding:CGFloat = 8.0
    
    var gridSize:CGFloat {
        return (collectionView!.bounds.height / gridRows) - (gridRows * gridPadding)
    }
    
    var attributesList = [StickyWallLayoutAttributes]()
    
    override var collectionViewContentSize: CGSize {
        var gridWidth:CGFloat = 0.0
        let height = collectionView!.bounds.height //height should always be the same
        
        for sectionIndex in 0..<collectionView!.numberOfSections {
            var bounds = StickyGridBounds()
            for itemIndex in 0..<collectionView!.numberOfItems(inSection: sectionIndex) {
                let attributes = layoutAttributesForItem(at: IndexPath(item: itemIndex, section: sectionIndex)) as! StickyWallLayoutAttributes
                bounds.encapsulate(position: attributes.position)
            }
            gridWidth += bounds.toCGSize().width
        }
        
        return CGSize(width: gridWidth * gridSize, height: height)
    }
    
    override func prepare() {
        super.prepare()
        
        for sectionIndex in 0..<collectionView!.numberOfSections {
            for itemIndex in 0..<collectionView!.numberOfItems(inSection: sectionIndex) {
                let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                let attributes = StickyWallLayoutAttributes(forCellWith: indexPath)
                attributes.position = StickyGridPosition(x: Int(floor(CGFloat(itemIndex) / gridRows)), y: itemIndex % Int(gridRows))
                attributesList.append(attributes)
            }
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return attributesList
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return attributesList.first { $0.indexPath == indexPath }
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

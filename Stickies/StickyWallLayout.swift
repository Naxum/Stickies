//
//  StickyWallLayout.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/10/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import UIKit

fileprivate let stickyRows:CGFloat = 4.0
fileprivate let gridRows:CGFloat = stickyRows * 2 // half steps!

class StickyWallLayout: UICollectionViewLayout {
    override class var layoutAttributesClass:AnyClass { return StickyWallLayoutAttributes.self }
    
    let gridPadding:CGFloat = 8.0
    let sectionPadding:CGFloat = 64.0
    
    var stickySize:CGFloat {
        return (collectionView!.bounds.height / stickyRows) - ((stickyRows - 2) * gridPadding)
    }
    
    var attributesList = [StickyWallLayoutAttributes]()
    
    override var collectionViewContentSize: CGSize {
        var gridWidth:CGFloat = 0.0
        let height = collectionView!.bounds.height //height should always be the same
        
        for sectionIndex in 0..<collectionView!.numberOfSections {
            var sectionBounds = StickyGridBounds()
            for itemIndex in 0..<collectionView!.numberOfItems(inSection: sectionIndex) {
                let attributes = layoutAttributesForItem(at: IndexPath(item: itemIndex, section: sectionIndex)) as! StickyWallLayoutAttributes
                sectionBounds.encapsulate(position: attributes.position)
            }
            gridWidth += CGFloat(sectionBounds.maxPosition.x) * 0.5 * stickySize + (CGFloat(sectionBounds.maxPosition.x + 1) * gridPadding)
        }
        
        return CGSize(width: gridWidth, height: height)
    }
    
    override func prepare() {
        super.prepare()
        
        var sectionOffset:CGFloat = 0
        for sectionIndex in 0..<collectionView!.numberOfSections {
            var maxPosX:CGFloat = 0
            for itemIndex in 0..<collectionView!.numberOfItems(inSection: sectionIndex) {
                let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                let gridPosX = Int(floor(CGFloat(itemIndex * 2) / gridRows) * 2)
                let gridPosY = (itemIndex * 2) % Int(gridRows)
                
                let attributes = StickyWallLayoutAttributes(forCellWith: indexPath)
                attributes.position = StickyGridPosition(x: gridPosX, y: gridPosY)
                attributes.size = CGSize(width: stickySize, height: stickySize)
                let posX = CGFloat(gridPosX) * 0.5 * stickySize + sectionOffset
                let posY = CGFloat(gridPosY) * 0.5 * stickySize
                let padding = CGPoint(x: gridPosX + 1, y: gridPosY + 1) * gridPadding
                attributes.center = CGPoint(x: posX, y: posY) + CGPoint(xy: stickySize * 0.5) + padding
                if attributes.center.x > maxPosX {
                    maxPosX = attributes.center.x
                }
                attributesList.append(attributes)
            }
            sectionOffset += sectionPadding + maxPosX + (stickySize * 0.5)
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

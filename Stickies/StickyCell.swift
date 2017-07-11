//
//  StickyCell.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/10/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import UIKit

class StickyCell: UICollectionViewCell {
    
    @IBOutlet fileprivate weak var thumbnailView: UIImageView! {
        didSet {
            thumbnailView.image = thumbnail
        }
    }
    
    var position = StickyGridPosition(x: 0, y: 0)
    
    var thumbnail:UIImage? {
        didSet {
            thumbnailView?.image = thumbnail
        }
    }
    
    override func prepareForReuse() {
        thumbnail = nil
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        let attributes = layoutAttributes as! StickyWallLayoutAttributes
    }

}

struct StickyGridPosition {
    var x:Int
    var y:Int
    
    func toCGPoint() -> CGPoint {
        return CGPoint(x: CGFloat(x) * 0.5, y: CGFloat(y) * 0.5)
    }
}

struct StickyGridBounds {
    var maxPosition = StickyGridPosition(x: 0, y: 0)
    
    mutating func encapsulate(position pos:StickyGridPosition) {
        if pos.x > maxPosition.x {
            maxPosition.x = pos.x
        }
        if pos.y > maxPosition.y {
            maxPosition.y = pos.y
        }
    }
    
    func toCGSize() -> CGSize {
        let point = maxPosition.toCGPoint()
        return CGSize(width: point.x, height: point.y)
    }
}

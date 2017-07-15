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
    
    var thumbnail:UIImage? {
        didSet {
            thumbnailView?.image = thumbnail
        }
    }
    
    override func prepareForReuse() {
        thumbnail = nil
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        //let attributes = layoutAttributes as! StickyWallLayoutAttributes
        
    }

}

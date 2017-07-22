//
//  StickyCell.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/10/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import UIKit

class StickyCell: UICollectionViewCell {
	@IBOutlet weak var label: UILabel!
	
    @IBOutlet fileprivate weak var thumbnailView: UIImageView! {
        didSet {
            thumbnailView.image = thumbnail
        }
    }
	
	fileprivate var moveIntentAnimation:UIViewPropertyAnimator?
	
    var thumbnail:UIImage? {
        didSet {
            thumbnailView?.image = thumbnail
        }
    }
    
    override func prepareForReuse() {
		thumbnail = nil
		moveIntentAnimation?.stopAnimation(true)
		moveIntentAnimation = nil
		contentView.transform = CGAffineTransform.identity
		alpha = 1
		contentView.alpha = 1
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
		
		contentView.cornerRadius = cornerRadius
		contentView.clipsToBounds = true
		let attributes = layoutAttributes as! StickyWallLayoutAttributes
		thumbnailView.backgroundColor = attributes.backgroundColor
		
		
    }
	
	func displayMoveRightIntent(display:Bool) {
		if moveIntentAnimation == nil && display {
			contentView.transform = CGAffineTransform.identity
			moveIntentAnimation = UIViewPropertyAnimator(duration: 0.25, curve: .easeInOut) { [unowned self] in
				self.contentView.transform = CGAffineTransform(translationX: self.bounds.width * 0.5, y: 0)
			}
			moveIntentAnimation!.pausesOnCompletion = true
		}
		
		moveIntentAnimation?.isReversed = !display
		moveIntentAnimation?.startAnimation()
	}
}

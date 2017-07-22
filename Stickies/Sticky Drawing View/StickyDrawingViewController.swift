//
//  StickyDrawingViewController.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/22/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import UIKit
import MetalKit

class StickyDrawingViewController: UIViewController {

	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var drawingView: StickyDrawingView!
	@IBOutlet weak var backgroundVFXView: UIVisualEffectView!
	
	var stickyNote:StickyNote!
	var originalStickyNoteFrame:CGRect!
	
	override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewDidAppear(_ animated: Bool) {
		backgroundVFXView.effect = nil
		backgroundVFXView.backgroundColor = UIColor(hue: 0, saturation: 0, brightness: 1, alpha: 0)
		drawingView.alpha = 0
		drawingView.backgroundColor = stickyNote.backgroundColor
		
		let fakeStickyCell = UIImageView(frame: originalStickyNoteFrame)
		fakeStickyCell.layer.cornerRadius = 8
		fakeStickyCell.backgroundColor = stickyNote.backgroundColor
		//		fakeStickyCell.image = loadedThumbnail
		view.addSubview(fakeStickyCell)
		
		let animator = UIViewPropertyAnimator(duration: 0.25, curve: .easeInOut) { [unowned self] in
			self.backgroundVFXView.effect = UIBlurEffect(style: .extraLight)
			self.backgroundVFXView.backgroundColor = UIColor(hue: 0, saturation: 0, brightness: 1, alpha: 0.5)
		}
		animator.addCompletion { _ in
			let anim2 = UIViewPropertyAnimator(duration: 0.25, curve: .easeInOut, animations: {
				fakeStickyCell.bounds = self.drawingView.bounds
				fakeStickyCell.center = self.drawingView.center
				fakeStickyCell.layer.cornerRadius = 0
			})
			anim2.addCompletion({ _ in
				fakeStickyCell.removeFromSuperview()
				self.drawingView.alpha = 1
				print("Completed 2!")
			})
			anim2.startAnimation()
			print("Completed 1!")
		}
		print("Duration: \(animator.duration)")
		animator.startAnimation()
	}
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

	@IBAction func dismiss(_ sender: Any) {
		guard let presenter = presentingViewController else {
			print("WOAH")
			return
		}
		
		presenter.dismiss(animated: true) {
			print("Dismissed!")
		}
	}
}

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
		//scroll view frame anchors
		scrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor)
		scrollView.frameLayoutGuide.leftAnchor.constraint(equalTo: view.leftAnchor)
		scrollView.frameLayoutGuide.rightAnchor.constraint(equalTo: view.rightAnchor)
		scrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		
		//scroll view content anchors
		scrollView.contentSize = scrollView.bounds.size
		drawingView.centerXAnchor.constraint(equalTo: scrollView.contentLayoutGuide.centerXAnchor)
		drawingView.centerYAnchor.constraint(equalTo: scrollView.contentLayoutGuide.centerYAnchor)
    }
	
	override func viewDidAppear(_ animated: Bool) {
		backgroundVFXView.effect = nil
		backgroundVFXView.backgroundColor = UIColor(hue: 0, saturation: 0, brightness: 1, alpha: 0)
		drawingView.alpha = 0
		drawingView.backgroundColor = stickyNote.backgroundColor
		drawingView.clipsToBounds = true
		drawingView.layer.masksToBounds = true
		drawingView.layer.borderWidth = 1
		drawingView.layer.borderColor = UIColor(hue: 0, saturation: 0, brightness: 1, alpha: 0.001).cgColor //literally can't have 0 alpha
		drawingView.layer.cornerRadius = 32
		
		let fakeStickyCell = UIImageView(frame: originalStickyNoteFrame)
		fakeStickyCell.layer.cornerRadius = 8
		fakeStickyCell.backgroundColor = stickyNote.backgroundColor
		//		fakeStickyCell.image = loadedThumbnail
		view.addSubview(fakeStickyCell)
		
		let animator = UIViewPropertyAnimator(duration: 0.4, curve: .easeInOut) { [unowned self] in
			self.backgroundVFXView.effect = UIBlurEffect(style: .extraLight)
			self.backgroundVFXView.backgroundColor = UIColor(hue: 0, saturation: 0, brightness: 1, alpha: 0.5)
		}
		animator.addCompletion { _ in
			let anim2 = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut, animations: {
				fakeStickyCell.bounds = self.drawingView.bounds
				fakeStickyCell.center = self.drawingView.center
				fakeStickyCell.layer.cornerRadius = 32
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

extension StickyDrawingViewController: UIScrollViewDelegate {
	func scrollViewDidZoom(_ scrollView: UIScrollView) {
		//TODO: dismiss self if we zoom out real low
	}
	
	func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
		//TODO: dismiss self if we zoom out real low
	}
	
	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return drawingView
	}
}

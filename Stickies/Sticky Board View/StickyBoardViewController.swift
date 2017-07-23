//
//  StickyBoardViewController.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/12/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import UIKit
import CoreData

class StickyBoardViewController: UIViewController {
	
	var stickyToDraw:StickyNote!
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func addNote(_ sender: UIButton) {
		// Hmm
		let newSticky = StickyHelper.addStickyNote()
		drawSeque(for: newSticky)
    }
	
	func drawSeque(for stickyNote:StickyNote) {
		stickyToDraw = stickyNote
		performSegue(withIdentifier: DrawingControllerSegue.identifier, sender: self)
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		// Get the new view controller using segue.destinationViewController.
		// Pass the selected object to the new view controller.
		guard let drawingController = segue.destination as? StickyDrawingViewController else {
			print("Wasn't drawing controller!")
			return
		}
		guard let wallController = childViewControllers.first as? StickyWallViewController else {
			print("Doesn't have board controller child!")
			return
		}
		
		let contentHeight = wallController.collectionView!.bounds.height
		let stickyFrame = stickyToDraw.gridPosition.getFrame(withContentHeight: contentHeight)
		let frame = wallController.collectionView!.convert(stickyFrame, to: view)
		
		drawingController.stickyNote = stickyToDraw
		drawingController.originalStickyNoteFrame = frame
	}
	
}

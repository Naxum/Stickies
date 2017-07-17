//
//  StickyWallCollectionViewController.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/10/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import UIKit
import CoreData

private let reuseIdentifier = "stickyCell"

class StickyWallViewController: UICollectionViewController {
	
	var fetchedController:NSFetchedResultsController<StickySection>!
	var layout:StickyWallLayout!
	var previousHoverCells = [StickyCell]()
	var previousHoverIndexPath:IndexPath?
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
//        self.collectionView!.register(StickyCell.self, forCellWithReuseIdentifier: reuseIdentifier)
		self.collectionView!.register(StickySectionBackgroundView.self, forSupplementaryViewOfKind: StickySectionBackgroundView.identifier, withReuseIdentifier: StickySectionBackgroundView.identifier)

		self.collectionView!.dragDelegate = self
		self.collectionView!.dropDelegate = self
//		self.collectionView!.reorderingCadence = .fast
		
        // Do any additional setup after loading the view.
		layout = StickyWallLayout()
        collectionView!.setCollectionViewLayout(layout, animated: false)
		
		let request:NSFetchRequest<StickySection> = StickySection.fetchRequest()
		request.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		request.predicate = NSPredicate(format: "board = %@ AND isTrashSection != YES", StickyHelper.currentBoard)
		fetchedController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: StickyHelper.managedContext, sectionNameKeyPath: nil, cacheName: nil)
		fetchedController.delegate = self
		try! fetchedController.performFetch()
		
		print("Found non-trash sections: \(fetchedController.fetchedObjects?.count ?? 0)")
    }
	
//	func removeSticky() {
//		let cell = sender.superview!.superview! as! StickyCell
//		let indexPath = collectionView!.indexPath(for: cell)!
//		StickyHelper.removeStickyNote(at: indexPath)
//	}
	
	// MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedController.fetchedObjects?.count ?? 0
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return fetchedController.fetchedObjects?.first(where: {$0.index == section})?.activeStickies.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! StickyCell
		cell.label.text = "\(indexPath.item)"
		//TODO: give cell its thumbnail
		
        return cell
    }
	
	override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		if kind != StickySectionBackgroundView.identifier {
			print("Unknown kind!")
		}
		let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: StickySectionBackgroundView.identifier, for: indexPath) as! StickySectionBackgroundView
		return view
	}

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}

extension StickyWallViewController: NSFetchedResultsControllerDelegate {
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		print("Did change content - fetched request controller!")
		collectionView?.reloadData()
	}
	
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		print("Will change content - fetched request controller!")
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		print("Did change at \(indexPath) -> \(newIndexPath), change type: \(type)")
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
		print("Did change section: \(sectionInfo), index: \(sectionIndex), type: \(type)")
	}
}

extension StickyWallViewController: UICollectionViewDragDelegate {
	func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
		// add items to an existing drag
		
		let provider = NSItemProvider(object: StickyNoteProvider(indexPath: indexPath))
		let dragItem = UIDragItem(itemProvider: provider)
		dragItem.localObject = StickyHelper.getSticky(at: indexPath)
		print("adding items to drag...")
		return [dragItem]
	}
	
	func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
		// handle start of drag
		let provider = NSItemProvider(object: StickyNoteProvider(indexPath: indexPath))
		let dragItem = UIDragItem(itemProvider: provider)
		dragItem.localObject = StickyHelper.getSticky(at: indexPath)
		print("items for beginning drag..")
		return [dragItem]
	}
}

extension StickyWallViewController: UICollectionViewDropDelegate {
//	func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
//		<#code#>
//	}
	
	func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
		
		// if we have a destination index path (ie, drag is hovering over existing sticky notes)
		if let destinationIndexPath = destinationIndexPath, let hoveringCell = collectionView.cellForItem(at: destinationIndexPath) as? StickyCell {
			
			// if the drag is not over an original sticky note
			if !session.items.contains(where: { ($0.localObject as! StickyNote).indexPath == destinationIndexPath }) {
				
				let hoveringSticky = StickyHelper.getSticky(at: destinationIndexPath)!
				
				// if the drag is not in the same index path position as last update
				if destinationIndexPath != previousHoverIndexPath {
					previousHoverCells.forEach { $0.displayMoveRightIntent(display: false) }
					previousHoverCells.removeAll()
					
					previousHoverCells.append(hoveringCell)
					previousHoverCells.append(contentsOf: StickyHelper.getStickies(pushedBy: hoveringSticky).map({collectionView.cellForItem(at: $0.indexPath) as! StickyCell}))
					previousHoverCells.forEach { $0.displayMoveRightIntent(display: true) }
					previousHoverIndexPath = destinationIndexPath
				}
			}
		} else {
			// not hovering over any
			previousHoverCells.forEach { $0.displayMoveRightIntent(display: false) }
		}
		
		return UICollectionViewDropProposal(operation: .move, intent: .unspecified)
	}
	
//	func collectionView(_ collectionView: UICollectionView, dragSessionAllowsMoveOperation session: UIDragSession) -> Bool {
//		<#code#>
//	}
	
	func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
		// undo any visual indicators that sticky notes were going to be pushed
		previousHoverCells.forEach { $0.displayMoveRightIntent(display: false) }
		previousHoverCells.removeAll()
		previousHoverIndexPath = nil
		
		guard let destinationIndexPath = coordinator.destinationIndexPath else {
			print("Don't support ambiguous drags to any location yet!")
			return
		}
		
		guard coordinator.items.count == 1 else {
			print("Don't support multiple stickies in a drag yet!")
			return
		}
		
		let stickyToMove = coordinator.session.items.first!.localObject as! StickyNote
		guard stickyToMove.indexPath != destinationIndexPath else {
			print("Moving one sticky to its same position... cancelling the drop")
			return
		}
		
		// right now moving one sticky to push an existing sticky rightward is the only supported drop type
		// this is very WIP
		
		let section = stickyToMove.section!
		let existingCell = collectionView.cellForItem(at: destinationIndexPath)!
		let cellToMove = collectionView.cellForItem(at: stickyToMove.indexPath)!
		cellToMove.contentView.alpha = 0 // hide the original cell while we drop the preview into the correct spot
		
		// wrapping everything in an animator gives a lot more control
		let dropAnimator = UIViewPropertyAnimator(duration: 0.25, curve: .easeInOut) {
			
			// drop the cell preview where the existing cell is
			coordinator.drop(coordinator.session.items.first!, to: UIDragPreviewTarget(container: collectionView, center: existingCell.center))
			
			// have the collection view smoothly animate all the cells' new positions
			collectionView.performBatchUpdates({
				// this pushes stickies to the right
				StickyHelper.move(stickyNote: stickyToMove, to: destinationIndexPath)
			})
		}
		
		// when the drop and other animations are complete...
		dropAnimator.addCompletion { _ in
			
			// make the real cell visible again
			cellToMove.contentView.alpha = 1
			
			// update all cells' indexes so they're correctly ordered (not sure if super necessary)
			section.refreshStickyIndexes()
			
			// section.refreshStickyIndexes doesn't actually save these new values (maybe move to StickyHelper?)
			try! StickyHelper.managedContext.save()
			
			// since there's no more or fewer stickies, we need to manually reload the data
			collectionView.reloadData()
		}
		
		// don't forget to start the animator!
		dropAnimator.startAnimation()
	}
	
	
}

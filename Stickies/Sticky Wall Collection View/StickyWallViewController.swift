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
	var boardController:StickyBoardViewController { return parent as! StickyBoardViewController }
	var fetchedController:NSFetchedResultsController<StickySection>!
	var layout:StickyWallLayout!
//	var previousHoverCells = [StickyCell]()
//	var previousHoverIndexPath:IndexPath?
	var currentDragResults = [Int: StickyDragResult]()
	var currentDragPlaceholders = [Int: [UIView]]()
	var currentRightIntents = [Int: [StickyCell]]()
	
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

	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		boardController.drawSeque(for: StickyHelper.getSticky(at: indexPath)!)
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
		let stickyNote = session.items.first!.localObject as! StickyNote
		let result = StickyHelper.getDragResult(for: stickyNote, from: session.location(in: collectionView), in: collectionView)
		
		if let currentResult = currentDragResults[session.hash] {
			//we have a current result
			if currentResult == result {
				//nothing has changed, let's bail
				return UICollectionViewDropProposal(operation: .move, intent: .unspecified)
			}
			
			//things HAVE changed, remove any placeholder views
			removeDragPlaceholders(for: session)
			
			currentRightIntents[session.hash]?.forEach { $0.displayMoveRightIntent(display: false) }
		}
		
		// add placeholder views!
		switch result {
		case .EmptyPosition(let position):
			print("Empty position: \(position)")
			_ = createPlaceholderView(at: position, forSession: session)
		case .OccupiedPosition(let position, let existingSticky):
			print("Occupied position: \(position)")
			_ = createPlaceholderView(at: position, forSession: session)
			for pushedSticky in StickyHelper.getStickies(pushedBy: existingSticky, includingPusher: true) {
				let cell = collectionView.cellForItem(at: pushedSticky.indexPath) as! StickyCell
				cell.displayMoveRightIntent(display: true)
				if currentRightIntents[session.hash] == nil {
					currentRightIntents[session.hash] = [StickyCell]()
				}
				currentRightIntents[session.hash]!.append(cell)
			}
		case .NewSection(let position, let insertAt):
			print("New section not yet implemented!")
		case .OutOfBounds:
			print("Not supporting out of bounds yet!")
		case .SamePosition:
			print("Same position!")
		}
		
		currentDragResults[session.hash] = result
		
		return UICollectionViewDropProposal(operation: .move, intent: .unspecified)
	}
	
	func createPlaceholderView(at position:StickyGridPosition, forSession session:UIDropSession) -> UIView {
		let view = UIView(frame: position.getFrame(withContentHeight: collectionView!.bounds.height))
		view.cornerRadius = 8
		view.backgroundColor = UIColor(hue: 0, saturation: 0, brightness: 0.8, alpha: 0.9)
		view.alpha = 0
		let animator = UIViewPropertyAnimator(duration: 0.25, curve: .easeInOut) {
			view.alpha = 1
		}
		animator.startAnimation()
		view.layer.zPosition = -0.5
		collectionView!.addSubview(view)
		if currentDragPlaceholders[session.hash] == nil {
			currentDragPlaceholders[session.hash] = [UIView]()
		}
		currentDragPlaceholders[session.hash]!.append(view)
		return view
	}
	
	func removeDragPlaceholders(for session:UIDropSession) {
		if let views = currentDragPlaceholders[session.hash] {
			let animator = UIViewPropertyAnimator(duration: 0.25, curve: .easeOut) {
				for placeholderView in views {
					placeholderView.alpha = 0
				}
			}
			animator.addCompletion({ _ in
				for placeholderView in views {
					placeholderView.removeFromSuperview()
				}
			})
			animator.startAnimation()
			currentDragPlaceholders.removeValue(forKey: session.hash)
		}
	}
	
//	func collectionView(_ collectionView: UICollectionView, dragSessionAllowsMoveOperation session: UIDragSession) -> Bool {
//		<#code#>
//	}
	
	func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
		// undo any visual indicators that sticky notes were going to be pushed
		currentRightIntents[coordinator.session.hash]?.forEach { $0.displayMoveRightIntent(display: false) }
		removeDragPlaceholders(for: coordinator.session)
		currentDragResults.removeValue(forKey: coordinator.session.hash)
		currentRightIntents.removeValue(forKey: coordinator.session.hash)
		
		
		guard coordinator.items.count == 1 else {
			print("Don't support multiple stickies in a drag yet!")
			return
		}
		
		let contentHeight = collectionView.bounds.height
		let stickyToMove = coordinator.session.items.first!.localObject as! StickyNote
		let fromIndexPath = stickyToMove.indexPath
		let cellToMove = collectionView.cellForItem(at: stickyToMove.indexPath)!
		cellToMove.contentView.alpha = 0
		
		let fromSection = stickyToMove.section!
		var toSection:StickySection?
		
		let dragResult = StickyHelper.getDragResult(for: stickyToMove, from: coordinator.session.location(in: collectionView), in: collectionView)
		
		let dropAnimator = UIViewPropertyAnimator(duration: 0.25, curve: .easeInOut) {
			switch dragResult {
			case .OutOfBounds: fallthrough
			case .SamePosition:
				print("Same position or out of bounds, cancelling.")
				
			case .EmptyPosition(let position):
				toSection = StickyHelper.getSection(at: position.sectionIndex)
				collectionView.performBatchUpdates({
					StickyHelper.move(stickyNote: stickyToMove, to: position)
					collectionView.moveItem(at: fromIndexPath, to: stickyToMove.indexPath)
				})
				
			case .OccupiedPosition(let position, _):
				toSection = StickyHelper.getSection(at: position.sectionIndex)
				collectionView.performBatchUpdates({
					StickyHelper.move(stickyNote: stickyToMove, to: position)
					collectionView.moveItem(at: fromIndexPath, to: stickyToMove.indexPath)
				})
				
			case .NewSection(let position, let insertAt):
				collectionView.performBatchUpdates({
					StickyHelper.insertSection(at: Int64(insertAt))
					StickyHelper.move(stickyNote: stickyToMove, to: position)
					collectionView.insertSections([insertAt])
					collectionView.moveItem(at: fromIndexPath, to: IndexPath(item: 0, section: insertAt))
				})
			}
			
			coordinator.drop(coordinator.session.items.first!, to: UIDragPreviewTarget(container: collectionView, center: stickyToMove.gridPosition.getFrame(withContentHeight: contentHeight).center))
		}
		
		dropAnimator.addCompletion { _ in
			// make the real cell visible again
			cellToMove.contentView.alpha = 1
			
			collectionView.performBatchUpdates({
				fromSection.cullEmptyColumns()
				toSection?.cullEmptyColumns()
			})
			
			fromSection.refreshStickyIndexes()
			toSection?.refreshStickyIndexes()
			
			// section.refreshStickyIndexes doesn't actually save these new values (maybe move to StickyHelper?)
			try! StickyHelper.managedContext.save()
		}
		
		// don't forget to start the animator!
		dropAnimator.startAnimation()
	}
}

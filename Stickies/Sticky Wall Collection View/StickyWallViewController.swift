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
	@IBOutlet var longPressRecognizer: UILongPressGestureRecognizer!
	
	var fetchedController:NSFetchedResultsController<StickySection>!
	var layout:StickyWallLayout!
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
//        self.collectionView!.register(StickyCell.self, forCellWithReuseIdentifier: reuseIdentifier)
		self.collectionView!.register(StickySectionBackgroundView.self, forSupplementaryViewOfKind: StickySectionBackgroundView.identifier, withReuseIdentifier: StickySectionBackgroundView.identifier)

		self.collectionView!.backgroundColor = UIColor.red
		
        // Do any additional setup after loading the view.
		layout = StickyWallLayout()
        collectionView!.setCollectionViewLayout(layout, animated: false)
		
		let request:NSFetchRequest<StickySection> = StickySection.fetchRequest()
		request.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		request.predicate = NSPredicate(format: "(board == %@) && (isTrashSection != YES)", StickyHelper.currentBoard)
		fetchedController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: StickyHelper.managedContext, sectionNameKeyPath: nil, cacheName: nil)
		fetchedController.delegate = self
		try! fetchedController.performFetch()
    }
	
	@IBAction func longPress(_ sender: UILongPressGestureRecognizer) {
		print("Long press!")
	}
	
	@IBAction func cellRemoveButtonPressed(_ sender: UIButton) {
		let cell = sender.superview!.superview! as! StickyCell
		let indexPath = collectionView!.indexPath(for: cell)!
		StickyHelper.removeStickyNote(at: indexPath)
		collectionView!.reloadData()
	}
	
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

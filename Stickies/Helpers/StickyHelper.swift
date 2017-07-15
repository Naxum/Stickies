//
//  StickyHelper.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/12/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import UIKit
import CoreData

class StickyHelper: NSObject {
	static var managedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	static var fetchedController:NSFetchedResultsController<StickyBoard> = {
		let request:NSFetchRequest<StickyBoard> = StickyBoard.fetchRequest()
		request.fetchLimit = 1
		request.sortDescriptors = [NSSortDescriptor(key: "lastOpened", ascending: false)]
		let result = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedContext, sectionNameKeyPath: nil, cacheName: nil)
		
		try! result.performFetch()
		
		if result.fetchedObjects?.first == nil {
			let board = StickyBoard(context: managedContext)
			board.title = "New Board"
			board.lastOpened = Date()
			board.lastModified = Date()
			try! managedContext.save()
			try! result.performFetch()
			print("Created first board: \(board)")
		}
		
		return result
	}()
	
	static var currentBoard:StickyBoard {
		return fetchedController.fetchedObjects!.first!
	}
	
	static func addStickyNote() -> StickyNote {
		print("------")
		print("Adding sticky note...")
		let existingSection = currentBoard.stickySections.max { $0.index < $1.index }
		let section = existingSection ?? StickySection(context: managedContext)
		
		let previousSticky = section.stickyNotes.max { $0.index < $1.index }
		print("Previous sticky: \(previousSticky?.index ?? -1) out of \(section.stickyNotes.count) stickies")
		
		let stickyNote = StickyNote(context: managedContext)
		stickyNote.index = (previousSticky?.index ?? -1) + 1
		stickyNote.localX = Int64(floor(Double(stickyNote.index) / 4)) * 2
		stickyNote.localY = (stickyNote.index % 4) * 2
		
		section.addToStickies(stickyNote)
		
		print("Added new sticky note: \(stickyNote)")
		if existingSection == nil {
			currentBoard.addToSections(section)
			print("Added new section: \(section)")
		}
		
		try! managedContext.save()
		return stickyNote
	}
}

extension StickyBoard {
	var stickySections:Set<StickySection> { return sections as! Set<StickySection> }
}

extension StickySection {
	var stickyNotes:Set<StickyNote> { return stickies as! Set<StickyNote> }
}

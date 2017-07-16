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
		let existingSection = currentBoard.activeSections.max { $0.index < $1.index }
		let section = existingSection ?? StickySection(context: managedContext)
		
		let gridCellsPerStickySize = Int(StickyGridSettings.gridCellsPerStickySize)
		
		let previousIndex = section.activeStickies.flatMap({ $0.index }).max()
		let furthestColumn = section.activeStickies.flatMap({$0.localX}).max()
		let previousSticky = section.activeStickies.filter({$0.localX == furthestColumn}).max { $0.localY < $1.localY }
		let previousPosition = StickyGridPosition(x: Int(previousSticky?.localX ?? 0), y: Int(previousSticky?.localY ?? Int64(-gridCellsPerStickySize)))
		
		let nextPosition:StickyGridPosition
		if previousPosition.gridPosY == Int(StickyGridSettings.gridRows) - gridCellsPerStickySize {
			nextPosition = StickyGridPosition(x: previousPosition.gridPosX + gridCellsPerStickySize, y: 0)
		} else {
			nextPosition = StickyGridPosition(x: previousPosition.gridPosX, y: previousPosition.gridPosY + gridCellsPerStickySize)
		}
		
		let stickyNote = StickyNote(context: managedContext)
		stickyNote.index = (previousIndex ?? -1) + 1
		stickyNote.localX = Int64(nextPosition.gridPosX)
		stickyNote.localY = Int64(nextPosition.gridPosY)
		
		section.addToStickies(stickyNote)
		
		print("Added new sticky note: \(stickyNote)")
		if existingSection == nil {
			currentBoard.addToSections(section)
			print("Added new section: \(section)")
		}
		
		try! managedContext.save()
		return stickyNote
	}
	
	static func removeStickyNote(at indexPath:IndexPath) {
		guard let section = currentBoard.activeSections.first(where: {$0.index == indexPath.section}) else {
			print("Could not find section at index path \(indexPath)")
			return
		}
		guard let stickyNote = section.activeStickies.first(where: {$0.index == indexPath.item}) else {
			print("Could not find sticky note to remove at index path \(indexPath)")
			return
		}
		
		print("Removing sticky note: \(stickyNote)")
		stickyNote.removed = true
		stickyNote.removedDate = Date()
		
		section.activeStickies.filter({$0.index >= stickyNote.index }).forEach { $0.index -= 1 }
		
		if currentBoard.trashSection == nil {
			currentBoard.trashSection = StickySection(context: managedContext)
			currentBoard.trashSection!.isTrashSection = true
			currentBoard.trashSection!.board = currentBoard
		}
		
		currentBoard.trashSection!.allStickies.forEach { $0.index += 1 }
		currentBoard.trashSection!.addToStickies(stickyNote)
		stickyNote.index = 0
		
		try! managedContext.save()
	}
}

extension StickyBoard {
	var activeSections:Set<StickySection> { return (sections as! Set<StickySection>).filter { !$0.isTrashSection } }
}

extension StickySection {
	var activeStickies:Set<StickyNote> { return (stickies as! Set<StickyNote>).filter { !$0.removed } }
	var allStickies:Set<StickyNote> { return stickies as! Set<StickyNote> }
}

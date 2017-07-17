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
	
	static func getSection(at index:Int) -> StickySection? {
		return currentBoard.activeSections.first(where: {$0.index == index})
	}
	
	static func getSection(at indexPath:IndexPath) -> StickySection? {
		return currentBoard.activeSections.first(where: {$0.index == indexPath.section})
	}
	
	static func getSticky(at indexPath:IndexPath) -> StickyNote? {
		guard let section = getSection(at: indexPath) else { return nil }
		return section.activeStickies.first(where: {$0.index == indexPath.item})
	}
	
	static func removeStickyNote(at indexPath:IndexPath) {
		guard let section = getSection(at: indexPath) else {
			print("Could not find section at index path \(indexPath)")
			return
		}
		guard let stickyNote = getSticky(at: indexPath) else {
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
	
	static func move(stickyNote:StickyNote, to indexPath: IndexPath) {
		guard let toSection = getSection(at: indexPath) else {
			print("Could not find section to move sticky note to! Index path: \(indexPath)")
			return
		}
		
		if stickyNote.section != toSection {
			// TODO: handle moving across sections
			print("We can't handle that yet!")
			return
		} else {
			// move to a new position in same section
			if let existingStickyNote = getSticky(at: indexPath) {
				// a sticky already exists here, we need to shift it and all ones on its right one sticky size to the right
				print("Moving \(stickyNote) to \(indexPath), which means we're moving \(existingStickyNote)")
				stickyNote.localX = existingStickyNote.localX
				stickyNote.localY = existingStickyNote.localY
				getStickies(pushedBy: existingStickyNote).forEach { $0.localX += Int64(StickyGridSettings.gridCellsPerStickySize) }
				existingStickyNote.localX += Int64(StickyGridSettings.gridCellsPerStickySize)
//				toSection.refreshStickyIndexes()
			} else {
				print("Attempted to move to \(indexPath), but there's no sticky there?")
			}
		}
		try! managedContext.save()
	}
	
	static func getStickies(pushedBy stickyNote:StickyNote) -> [StickyNote] {
		var result = [StickyNote]()
		let allStickiesToRight = stickyNote.section!.activeStickies.filter {
			$0.localX > stickyNote.localX && $0.localY >= stickyNote.localY - 1 && $0.localY <= stickyNote.localY + 1
			}
		var currentX = stickyNote.localX + Int64(StickyGridSettings.gridCellsPerStickySize)
		for sticky in allStickiesToRight.sorted(by: { $0.localX < $1.localX }) {
			guard sticky.localX == currentX else { continue }
			result.append(sticky)
			currentX += Int64(StickyGridSettings.gridCellsPerStickySize)
		}
		return result
	}
}

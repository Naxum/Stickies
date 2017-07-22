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
		
		let previousIndex = section.activeStickies.flatMap({ $0.index }).max()
		let furthestColumn = section.activeStickies.flatMap({$0.localX}).max()
		let previousSticky = section.activeStickies.filter({$0.localX == furthestColumn}).max { $0.localY < $1.localY }
		let previousPosition = previousSticky?.gridPosition ?? StickyGridPosition(x: 0, y: -1, section: Int(section.index))
		
		let nextPosition:StickyGridPosition
		if previousPosition.gridPosY == Int(StickyGridSettings.gridRows) - 1 {
			nextPosition = StickyGridPosition(x: previousPosition.gridPosX + 1, y: 0, section: Int(section.index))
		} else {
			nextPosition = StickyGridPosition(x: previousPosition.gridPosX, y: previousPosition.gridPosY + 1, section: Int(section.index))
		}
		
		let stickyNote = StickyNote(context: managedContext)
		stickyNote.backgroundColor = [UIColor.yellow, UIColor.red, UIColor.cyan, UIColor.green].random()
		stickyNote.index = (previousIndex ?? -1) + 1
		stickyNote.localX = Int64(nextPosition.gridPosX)
		stickyNote.localY = Int64(nextPosition.gridPosY)
		
		section.addToStickies(stickyNote)
		
		print("Added new sticky note: \(stickyNote)")
		if existingSection == nil {
			currentBoard.addToSections(section)
			print("Added new section: \(section)")
		}
		
		section.refreshMaxGridX()
		
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
	
	static func getSticky(at position:StickyGridPosition, inSection section:Int) -> StickyNote? {
		guard let section = getSection(at: section) else { return nil }
		return section.activeStickies.first(where: {$0.localX == position.gridPosX && $0.localY == position.gridPosY})
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
		
		section.refreshMaxGridX()
		
		try! managedContext.save()
	}
	
	static func insertSection(at index:Int64) {
		let newSection = StickySection(context: StickyHelper.managedContext)
		currentBoard.activeSections.filter({ $0.index >= index }).forEach { $0.index += 1}
		newSection.index = index
		currentBoard.addToSections(newSection)
	}
	
	static func move(stickyNote:StickyNote, to position:StickyGridPosition) {
		if stickyNote.section!.index != position.sectionIndex {
			let fromSection = stickyNote.section
			fromSection?.removeFromStickies(stickyNote)
			fromSection?.refreshStickyIndexes()
			
			let toSection = getSection(at: position.sectionIndex)!
			toSection.addToStickies(stickyNote)
			stickyNote.index = 0
		}
		
		let toSection = getSection(at: position.sectionIndex)!
		
		let x = Int64(position.gridPosX)
		let y = Int64(position.gridPosY)
		
		if let existingSticky = toSection.activeStickies.first(where: { $0.localX == x && $0.localY == y }) {
			getStickies(pushedBy: existingSticky, includingPusher: true).forEach { $0.localX += 1 }
		}
		
		stickyNote.localX = x
		stickyNote.localY = y
		
		stickyNote.section!.refreshMaxGridX()
		if stickyNote.section != toSection {
			let oldSection = stickyNote.section
			oldSection?.removeFromStickies(stickyNote)
			oldSection?.refreshStickyIndexes()
			oldSection?.refreshMaxGridX()
			
			toSection.addToStickies(stickyNote)
		}
		
		toSection.refreshStickyIndexes()
		toSection.refreshMaxGridX()
		
		try! managedContext.save()
	}
	
	static func getStickies(pushedBy stickyNote:StickyNote, includingPusher:Bool) -> [StickyNote] {
		var result = [StickyNote]()
		if includingPusher {
			result.append(stickyNote)
		}
		let allStickiesToRight = stickyNote.section!.activeStickies.filter {
			$0.localX > stickyNote.localX && $0.localY == stickyNote.localY
			}
		var currentX = stickyNote.localX + 1
		for sticky in allStickiesToRight.sorted(by: { $0.localX < $1.localX }) {
			guard sticky.localX == currentX else { continue }
			result.append(sticky)
			currentX += 1
		}
		return result
	}
	
	static func getGridPosY(fromY y:CGFloat, inBounds height:CGFloat) -> Int {
		let offset = StickyGridSettings.boardPadding + StickyGridSettings.sectionPadding
		let interiorY = y - offset
		let interiorHeight = height - (offset * 2)
		let heightPercentage = interiorY / interiorHeight
		return min(max(Int(floor(heightPercentage * StickyGridSettings.gridRows)), 0), Int(StickyGridSettings.gridRows))
	}
	
	static func getDragResult(for stickyNote:StickyNote, from location:CGPoint, in view:UICollectionView) -> StickyDragResult {
		let height = view.bounds.height
		let gridY = getGridPosY(fromY: location.y, inBounds: height)
		let newSectionBounds = CGRect(origin: CGPoint(xy: 0), size: CGSize(width: StickyGridSettings.boardPadding, height: height))
		if newSectionBounds.contains(location) {
			return .NewSection(position: StickyGridPosition(x: 0, y: gridY, section: 0), insertAt: 0)
		}
		
		for section in currentBoard.activeSections {
			let maxX = Int(section.maxGridX)
			for gridX in 0...maxX {
				let gridPos = StickyGridPosition(x: gridX, y: gridY, section: Int(section.index))
				let gridFrame = gridPos.getFrame(withContentHeight: height)
				var hitboxSize = CGSize(width: gridFrame.size.width, height: gridFrame.size.height + StickyGridSettings.gridSpacing)
				if gridX != maxX {
					hitboxSize = CGSize(width: hitboxSize.width + StickyGridSettings.gridSpacing, height: hitboxSize.height)
				}
				let hitbox = CGRect(origin: gridFrame.origin, size: hitboxSize)
				
				if hitbox.contains(location) {
					//moving to this position!
					if let existingSticky = getSticky(at: gridPos, inSection: Int(section.index)) {
						if existingSticky == stickyNote {
							return .SamePosition
						} else {
							return .OccupiedPosition(position: gridPos, existingSticky: existingSticky)
						}
					} else {
						return .EmptyPosition(position: gridPos)
					}
				}
			}
			
			//include the last x spacing from the grids in this rectangle
			let sectionRect = try! currentBoard.getSectionFrame(section: section, withContentHeight: height)
			let sectionSpacingRect = CGRect(x: sectionRect.maxX - StickyGridSettings.gridSpacing, y: sectionRect.minY, width: StickyGridSettings.gridSpacing + StickyGridSettings.sectionOffsetSpacing, height: sectionRect.height)
			
			if sectionSpacingRect.contains(location) {
				//we're between two sections!
				if location.x <= sectionSpacingRect.minX + StickyGridSettings.gridSpacing + (StickyGridSettings.sectionOffsetSpacing / 2) {
					return .EmptyPosition(position: StickyGridPosition(x: Int(section.maxGridX) + 1, y: gridY, section: Int(section.index)))
				} else {
					let insertIndex = Int(section.index) + 1
					return .NewSection(position: StickyGridPosition(x: 0, y: gridY, section: insertIndex), insertAt: insertIndex)
				}
			}
		}
		
		return .OutOfBounds
	}
}

enum StickyDragResult {
	case OutOfBounds
	case SamePosition
	case EmptyPosition(position:StickyGridPosition)
	case OccupiedPosition(position:StickyGridPosition, existingSticky:StickyNote)
	case NewSection(position:StickyGridPosition, insertAt:Int)
	
	static func == (left:StickyDragResult, right: StickyDragResult) -> Bool {
		switch (left, right) {
			case (.OutOfBounds, .OutOfBounds): return true
			case (.SamePosition, .SamePosition): return true
			case let (.EmptyPosition(a1), .EmptyPosition(a2)): return a1 == a2
			case let (.OccupiedPosition(a1, b1), .OccupiedPosition(a2, b2)): return a1 == a2 && b1 == b2
			case let (.NewSection(a1, b1), .NewSection(a2, b2)): return a1 == a2 && b1 == b2
			default: return false;
		}
	}
}

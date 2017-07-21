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
	
	static func move(stickyNote:StickyNote, to position:StickyGridPosition) {
		guard stickyNote.section!.index == position.sectionIndex else {
			print("Hey! That's not currently allowed!")
			return
		}
		
		stickyNote.localX = Int64(position.gridPosX)
		stickyNote.localY = Int64(position.gridPosY)
		
		stickyNote.section!.refreshMaxGridX()
		
		try! managedContext.save()
	}
	
	static func move(stickyNote:StickyNote, byPushing noteToPush: StickyNote) {
		if stickyNote.section != noteToPush.section {
			// TODO: handle moving across sections
			print("We can't handle that yet!")
			//refreshMaxX(of: stickyNote.section)
			return
		} else {
			// a sticky already exists here, we need to shift it and all ones on its right one sticky size to the right
			stickyNote.localX = noteToPush.localX
			stickyNote.localY = noteToPush.localY
			getStickies(pushedBy: noteToPush, includingPusher: true).forEach { $0.localX += 1 }
		}
		
		if noteToPush.section != stickyNote.section {
			let oldSection = stickyNote.section!
			stickyNote.section!.removeFromStickies(stickyNote)
			noteToPush.section!.addToStickies(stickyNote)
			oldSection.refreshMaxGridX()
		}
		
		noteToPush.section!.refreshMaxGridX()
		
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
		return Int(floor(heightPercentage * StickyGridSettings.gridRows))
	}
	
	static func getDragResult(for stickyNote:StickyNote, from location:CGPoint, in view:UICollectionView) -> StickyDragResult {
		let height = view.bounds.height
		let gridY = getGridPosY(fromY: location.y, inBounds: height)
		print("GridY: \(gridY)")
		let newSectionBounds = CGRect(origin: CGPoint(xy: 0), size: CGSize(width: StickyGridSettings.boardPadding, height: height))
		if newSectionBounds.contains(location) {
			return .NewSection(position: StickyGridPosition(x: 0, y: gridY, section: -1), after: nil, before: getSection(at: 0)!)
		}
		
		for section in currentBoard.activeSections.sorted(by: { $0.index < $1.index }) {
			for gridX in 0...Int(section.maxGridX) {
				let gridPos = StickyGridPosition(x: gridX, y: gridY, section: Int(section.index))
				let gridFrame = gridPos.getFrame(withContentHeight: height)
				var hitboxSize = CGSize(width: gridFrame.size.width, height: gridFrame.size.height + StickyGridSettings.gridSpacing)
				if gridX != Int(section.maxGridX) {
					hitboxSize = CGSize(width: hitboxSize.width + StickyGridSettings.gridSpacing, height: hitboxSize.height)
				}
				let hitbox = CGRect(origin: gridFrame.origin, size: hitboxSize)
				print("Hitbox size: \(hitboxSize)")
				
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
			let sectionSpacingRect = CGRect(x: sectionRect.maxX, y: sectionRect.minY, width: StickyGridSettings.gridSpacing + StickyGridSettings.sectionOffsetSpacing, height: sectionRect.height)
			
			if sectionSpacingRect.contains(location) {
				//we're between two sections!
				if location.x <= sectionSpacingRect.minX + StickyGridSettings.gridSpacing {
					return .EndOfSection(position: StickyGridPosition(x: Int(section.maxGridX) + 1, y: gridY, section: Int(section.index)))
				} else {
					return .NewSection(position: StickyGridPosition(x: 0, y: gridY, section: Int(section.index + 1)), after: section, before: getSection(at: Int(section.index) + 1))
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
	case EndOfSection(position:StickyGridPosition)
	case NewSection(position:StickyGridPosition, after:StickySection?, before:StickySection?)
	
	static func == (left:StickyDragResult, right: StickyDragResult) -> Bool {
		switch (left, right) {
			case (.OutOfBounds, .OutOfBounds): return true
			case (.SamePosition, .SamePosition): return true
			case let (.EmptyPosition(a1), .EmptyPosition(a2)): return a1 == a2
			case let (.OccupiedPosition(a1, b1), .OccupiedPosition(a2, b2)): return a1 == a2 && b1 == b2
			case let (.EndOfSection(a1), .EndOfSection(a2)): return a1 == a2
			case let (.NewSection(a1, b1, c1), .NewSection(a2, b2, c2)): return a1 == a2 && b1 == b2 && c1 == c2;
			default: return false;
		}
	}
}

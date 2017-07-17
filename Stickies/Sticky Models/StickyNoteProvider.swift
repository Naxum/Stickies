//
//  StickyNoteProvider.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/16/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import UIKit

class StickyNoteProvider: NSObject, NSItemProviderReading, NSItemProviderWriting {
	static let typeIdentifier = "com.naxite.sticky"
	
	var indexPath:IndexPath
	
	required init(itemProviderData data: Data, typeIdentifier: String) throws {
		guard typeIdentifier == StickyNoteProvider.typeIdentifier else { throw StickyNoteProviderError.unsupportedTypeIdentifier }
		indexPath = try! JSONDecoder().decode(IndexPath.self, from: data)
	}
	
	init(indexPath:IndexPath) {
		self.indexPath = indexPath
	}
	
	// reading
	public static var readableTypeIdentifiersForItemProvider: [String] {
		return [StickyNoteProvider.typeIdentifier] //TODO: eventully add public.image and include image-based sticky notes
	}
	
	// writing
	public static var writableTypeIdentifiersForItemProvider: [String] {
		return [StickyNoteProvider.typeIdentifier] //TODO: eventually add public.image and export the sticky's image to other apps
	}
	
	public func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
		guard typeIdentifier == StickyNoteProvider.typeIdentifier else {
			print("Unknown type identifier: \(typeIdentifier)")
			return nil
		}
		completionHandler(try! JSONEncoder().encode(indexPath), nil)
		return nil
	}
	
	enum StickyNoteProviderError: Error {
		case unsupportedTypeIdentifier
	}
}

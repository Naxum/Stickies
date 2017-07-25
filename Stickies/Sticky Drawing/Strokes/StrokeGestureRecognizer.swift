//
//  StrokeGestureRecognizer.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/23/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

class StrokeGestureRecognizer: UIGestureRecognizer {
	let smoother = TouchSmoother()
	let predictiveSmoother = TouchSmoother()
	
	override init(target: Any?, action: Selector?) {
		super.init(target: target, action: action)
		setup()
	}
	
	fileprivate func setup() {
		allowedTouchTypes = [UITouchType.stylus.rawValue as NSNumber]
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
		guard let firstTouch = touches.first, let view = view else {
			state = .failed
			return
		}
		
		smoother.startNewStroke()
		predictiveSmoother.startNewStroke()
		
		event.coalescedTouches(for: firstTouch)?.forEach {
			smoother.handle(touch: $0, in: view)
		}
		event.predictedTouches(for: firstTouch)?.forEach {
			predictiveSmoother.handle(touch: $0, in: view)
		}
		
		state = .began
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
		guard let firstTouch = touches.first, let view = view else {
			return
		}
		
		predictiveSmoother.continueStroke()
		
		event.coalescedTouches(for: firstTouch)?.forEach {
			smoother.handle(touch: $0, in: view)
		}
		event.predictedTouches(for: firstTouch)?.forEach {
			predictiveSmoother.handle(touch: $0, in: view)
		}
		
		state = .changed
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
		guard let firstTouch = touches.first, let view = view else {
			return
		}
		
		predictiveSmoother.continueStroke()
		
		event.coalescedTouches(for: firstTouch)?.forEach {
			smoother.handle(touch: $0, in: view)
		}
		event.predictedTouches(for: firstTouch)?.forEach {
			predictiveSmoother.handle(touch: $0, in: view)
		}
		
		state = .ended
	}
	
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
		smoother.startNewStroke()
		predictiveSmoother.startNewStroke()
		state = .cancelled
	}
	
	override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {
		//TODO: Maybe utilize this to redraw strokes with new correct values?
	}
}

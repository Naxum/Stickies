//
//  StickyDrawingView.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/22/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import UIKit
import MetalKit

class StickyDrawingView: MTKView {

	var vertexBuffer:MTLBuffer!
	let vertexData: [Float] = [
		0,  1, 0,
		-1, -1, 0,
		1, -1, 0
	]
	var pipelineState:MTLRenderPipelineState!
	var commandQueue:MTLCommandQueue!
	var timer:CADisplayLink!
	
	override init(frame frameRect: CGRect, device: MTLDevice?) {
		super.init(frame: frameRect, device: device)
		setup()
	}
	
	required init(coder: NSCoder) {
		super.init(coder: coder)
		setup()
	}
	
	func setup() {
		device = MTLCreateSystemDefaultDevice()
		guard let device = device else {
			print("Could not setup with MTLDevice!")
			return
		}
		
		vertexBuffer = device.makeBuffer(bytes: vertexData, length: MemoryLayout<Float>.size * vertexData.count, options: [])
		let defaultLibrary = try! device.makeDefaultLibrary(bundle: .main)
		let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")!
		let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")!
		
		let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
		pipelineStateDescriptor.vertexFunction = vertexProgram
		pipelineStateDescriptor.fragmentFunction = fragmentProgram
		pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float
		pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
		
		pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
		commandQueue = device.makeCommandQueue()!
		timer = CADisplayLink(target: self, selector: #selector(update))
		timer.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
		
		print("Sticky Drawing View Setup!")
	}
	
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
		guard let renderPassDescriptor = currentRenderPassDescriptor,
			  let drawable = currentDrawable else {
			print("Could not get currentRenderPassDescriptor and/or currentDrawable")
			return
		}
		
		let commandBuffer = commandQueue.makeCommandBuffer()!
		let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
		renderEncoder.setRenderPipelineState(pipelineState)
		renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
		renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
		renderEncoder.endEncoding()
		
		commandBuffer.present(drawable)
		commandBuffer.commit()
    }
	
	@objc func update() {
		autoreleasepool {
			draw()
		}
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		print("Touches began \(touches) with \(event)")
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		print("Touches moved \(touches) with \(event)")
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		print("Touches ended \(touches) with \(event)")
	}
	
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		print("Touches cancelled \(touches) with \(event)")
	}
}

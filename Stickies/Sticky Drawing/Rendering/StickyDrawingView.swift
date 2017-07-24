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
	// universal
	fileprivate var pipelineState:MTLRenderPipelineState!
	fileprivate var commandQueue:MTLCommandQueue!
	fileprivate var timer:CADisplayLink!
	fileprivate var brushTexture:MTLTexture!
	fileprivate var stickyTexture:MTLTexture!
	
	// interactions
	fileprivate var strokeGesture:StrokeGestureRecognizer!
	
	// per frame
	fileprivate let inflightSemaphore = DispatchSemaphore(value: 3)
	fileprivate var vertexBuffer:MTLBuffer!
	fileprivate var stampBuffer:MTLBuffer!
	fileprivate var stampCount:Int = 0
	
	override init(frame frameRect: CGRect, device: MTLDevice?) {
		super.init(frame: frameRect, device: device)
		setup()
	}
	
	required init(coder: NSCoder) {
		super.init(coder: coder)
		setup()
	}
	
	func setup() {
		layer.isOpaque = false
		
		device = MTLCreateSystemDefaultDevice()
		guard let device = device else {
			print("Could not setup with MTLDevice!")
			return
		}
		
		let defaultLibrary = try! device.makeDefaultLibrary(bundle: .main)
		let fragmentProgram = defaultLibrary.makeFunction(name: "render_vertex")!
		let vertexProgram = defaultLibrary.makeFunction(name: "pass_vertex")!
		
		let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
		pipelineStateDescriptor.vertexFunction = vertexProgram
		pipelineStateDescriptor.fragmentFunction = fragmentProgram
		pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float
		pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
		pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
		pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
		pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
		pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
		pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
		pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
		pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
		
		pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
		commandQueue = device.makeCommandQueue()!
		commandQueue.label = "main command queue"
		timer = CADisplayLink(target: self, selector: #selector(update))
		timer.preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
		preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
		timer.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
		
		let png = UIImagePNGRepresentation(#imageLiteral(resourceName: "brush_shape"))! //brush_shape image
		brushTexture = try! MTKTextureLoader(device: device).newTexture(with: png, options: nil)
		
		vertexBuffer = device.makeBuffer(bytes: Quad().vertices, length: MemoryLayout<Vertex>.stride * 6, options: [])
		vertexBuffer.label = "vertex buffer"
		
		stampBuffer = device.makeBuffer(length: MemoryLayout<Stamp>.size * 3 * 1024, options: [])
		stampBuffer.label = "stamp buffer"
		stickyTexture = device.makeTexture(descriptor: MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: 2048, height: 2048, mipmapped: false))!
		
		let simpleStamp = Stamp(x: 0, y: 0, white: true, alpha: 0.5, width: 1024, height: 1024, rotation: Float.pi * 0.25)
		stampBuffer.contents().storeBytes(of: simpleStamp, toByteOffset: 0, as: Stamp.self)
		stampCount = 1
		
		strokeGesture = StrokeGestureRecognizer(target: self, action: #selector(StickyDrawingView.strokeUpdated))
		addGestureRecognizer(strokeGesture)
		
		isPaused = true
		enableSetNeedsDisplay = true
//		framebufferOnly = false
		
		setNeedsDisplay()
		print("Sticky Drawing View Setup!")
	}
	
	@objc func strokeUpdated(gesture:StrokeGestureRecognizer) {
		guard gesture.state != .cancelled, gesture.state != .failed else { return }
		
		gesture.smoother.smoothedPoints.forEach {
			let x = ($0.x / Float(bounds.width)) * DrawingSettings.canvasSize
			let y = ((Float(bounds.height) - $0.y) / Float(bounds.height)) * DrawingSettings.canvasSize
			let stamp = Stamp(x: x, y: y, white: true, alpha: 0.5, width: 50, height: 50, rotation: 0)
			stampBuffer.contents().storeBytes(of: stamp, toByteOffset: stampCount * MemoryLayout<Stamp>.stride, as: Stamp.self)
			stampCount += 1
		}
		
		gesture.smoother.reset()
		
		if stampCount > 0 {
			setNeedsDisplay()
		}
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
		guard stampCount > 0 else { return }
		
		let commandBuffer = commandQueue.makeCommandBuffer()!
		let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
		renderEncoder.label = "render quads encoder"
		renderEncoder.pushDebugGroup("render quads")
		renderEncoder.setRenderPipelineState(pipelineState)
		renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
		renderEncoder.setVertexBuffer(stampBuffer, offset: 0, index: 1)
		renderEncoder.setFragmentTexture(brushTexture, index: 0)
		renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: stampCount)
		renderEncoder.popDebugGroup()
		renderEncoder.endEncoding()
		
		commandBuffer.present(drawable)
		commandBuffer.commit()
		
		stampCount = 0
    }
	
	@objc func update() {
		autoreleasepool {
			draw()
		}
	}

}

//
//  StickyDrawingView.swift
//  Stickies
//
//  Created by Jacob Sawyer on 7/22/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

import UIKit
import MetalKit
import GLKit

class StickyDrawingView: MTKView {
	static let frameCount = 3
	static let stampBufferOffset = 512 * MemoryLayout<Stamp>.stride
	
	// settings
	var erasing = false
	
	// universal
	fileprivate var renderPipelineState:MTLRenderPipelineState!
	fileprivate var subtractPipelineState:MTLRenderPipelineState!
	fileprivate var commandQueue:MTLCommandQueue!
	
	// timers
	fileprivate let semaphore = DispatchSemaphore(value: frameCount)
	
	// textures
	fileprivate var brushTexture:MTLTexture!
	fileprivate var stickyTexture:MTLTexture!
	
	// buffers
	fileprivate var vertexBuffer:MTLBuffer!
	fileprivate var stampBuffer:MTLBuffer!
	fileprivate var canvasBuffer:MTLBuffer!
	fileprivate var canvasBytesPerRow:Int = 0
	
	// interactions
	fileprivate var strokeGesture:StrokeGestureRecognizer!
	fileprivate var frameIndex = 0
	fileprivate var stampCount = [Int](repeating: 0, count: frameCount)
	fileprivate var needsAdditionalRender = false
	
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
		let vertexProgram = defaultLibrary.makeFunction(name: "pass_stamp_vertex")!
		let fragmentProgram = defaultLibrary.makeFunction(name: "render_vertex")!
		let subtractColorProgram = defaultLibrary.makeFunction(name: "subtract_from_color")!
		
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
		
		renderPipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
		
		pipelineStateDescriptor.fragmentFunction = subtractColorProgram;
		subtractPipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
		
		commandQueue = device.makeCommandQueue()!
		commandQueue.label = "main command queue"
		
		preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
		
		let png = UIImagePNGRepresentation(#imageLiteral(resourceName: "brush_shape"))! //brush_shape image
		brushTexture = try! MTKTextureLoader(device: device).newTexture(with: png, options: nil)
		
		vertexBuffer = device.makeBuffer(bytes: Quad().vertices, length: MemoryLayout<Vertex>.stride * 6, options: [])
		vertexBuffer.label = "vertex buffer"
		
		// add one extra Stamp's stride to the end for full-screen stamps
		stampBuffer = device.makeBuffer(length: (StickyDrawingView.stampBufferOffset * StickyDrawingView.frameCount) + MemoryLayout<Stamp>.stride, options: [])
		stampBuffer.label = "stamp buffer"
		
		let canvasSize = Int(DrawingSettings.canvasSize)
		canvasBytesPerRow = canvasSize * MemoryLayout<GLKVector4>.stride
		canvasBuffer = device.makeBuffer(length: canvasSize * canvasBytesPerRow, options: .cpuCacheModeWriteCombined) //might not need this option
		canvasBuffer.label = "canvas buffer"
		
		let stickyTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: canvasSize, height: canvasSize, mipmapped: false)
		stickyTextureDescriptor.usage = [.shaderRead, .renderTarget]
		stickyTexture = device.makeTexture(descriptor: stickyTextureDescriptor)!
		stickyTexture.label = "sticky canvas texture"
		
		strokeGesture = StrokeGestureRecognizer(target: self, action: #selector(StickyDrawingView.strokeUpdated))
		addGestureRecognizer(strokeGesture)
		
		print("Sticky Drawing View Setup!")
	}
	
	@objc func strokeUpdated(gesture:StrokeGestureRecognizer) {
		guard gesture.state != .cancelled, gesture.state != .failed else { return }
		
		let frameOffset = StickyDrawingView.stampBufferOffset * frameIndex
		gesture.smoother.smoothedPoints.forEach {
			let x = ($0.x / Float(bounds.width)) * DrawingSettings.canvasSize
			let y = ((Float(bounds.height) - $0.y) / Float(bounds.height)) * DrawingSettings.canvasSize
			let stamp = Stamp(x: x, y: y, white: !erasing, alpha: 0.25, width: 25, height: 25, rotation: 0)
			stampBuffer.contents().storeBytes(of: stamp, toByteOffset: frameOffset + stampCount[frameIndex] * MemoryLayout<Stamp>.stride, as: Stamp.self)
			stampCount[frameIndex] += 1
		}
		
		gesture.smoother.continueStroke()
//		isPaused = false
	}
	
    override func draw(_ rect: CGRect) {
		semaphore.wait()
		
		guard let renderPassDescriptor = currentRenderPassDescriptor,
			let drawable = currentDrawable else {
				print("Could not get currentRenderPassDescriptor and/or currentDrawable")
				return
		}
		
		let commandBuffer = commandQueue.makeCommandBuffer()!
		commandBuffer.label = "frame \(frameIndex) command buffer"
		commandBuffer.addCompletedHandler { [weak self] _ in
			self?.semaphore.signal()
		}
		
		if stampCount[frameIndex] > 0 {
			renderPassDescriptor.colorAttachments[0].loadAction = .load
			renderPassDescriptor.colorAttachments[0].texture = stickyTexture
			let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
			renderEncoder.label = "render quads encoder"
			renderEncoder.pushDebugGroup("render quads to texture group")
			renderEncoder.setRenderPipelineState(renderPipelineState)
			renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
			renderEncoder.setVertexBuffer(stampBuffer, offset: StickyDrawingView.stampBufferOffset * frameIndex, index: 1)
			renderEncoder.setFragmentTexture(brushTexture, index: 0)
			renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: stampCount[frameIndex])
			renderEncoder.popDebugGroup()
			renderEncoder.endEncoding()
			needsAdditionalRender = true
		} else {
			needsAdditionalRender = false
		}
		
		renderPassDescriptor.colorAttachments[0].loadAction = .clear
		renderPassDescriptor.colorAttachments[0].texture = drawable.texture
		let subtractEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
		subtractEncoder.label = "subtract texture encoder"
		subtractEncoder.pushDebugGroup("subtract texture group")
		subtractEncoder.setRenderPipelineState(subtractPipelineState)
		subtractEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
		let stamp = Stamp.fullscreen(texture: drawable.texture, withColor: backgroundColor!)
		let stampOffset = StickyDrawingView.stampBufferOffset * StickyDrawingView.frameCount
		stampBuffer.contents().storeBytes(of: stamp, toByteOffset: stampOffset, as: Stamp.self)
		subtractEncoder.setVertexBuffer(stampBuffer, offset: stampOffset, index: 1)
		subtractEncoder.setFragmentTexture(stickyTexture, index: 0)
		subtractEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: 1)
		subtractEncoder.popDebugGroup()
		subtractEncoder.endEncoding()
		
//		stickyTexture.getBytes(canvasBuffer.contents(), bytesPerRow: canvasBytesPerRow, from: drawable.texture.region, mipmapLevel: 0)
//		drawable.texture.replace(region: drawable.texture.region, mipmapLevel: 0, withBytes: canvasBuffer.contents(), bytesPerRow: canvasBytesPerRow)
		
		commandBuffer.present(drawable)
		commandBuffer.commit()
		
		stampCount[frameIndex] = 0
		frameIndex = (frameIndex + 1) % StickyDrawingView.frameCount
//		isPaused = !needsAdditionalRender
	}

}

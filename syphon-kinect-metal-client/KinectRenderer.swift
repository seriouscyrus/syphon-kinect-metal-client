//
//  Renderer.swift
//  syphon-kinect-metal-client
//
//  Created by George Brown on 10.02.20.
//  Copyright © 2020 George Brown. All rights reserved.
//

import MetalKit

class KinectRenderer: NSObject, MTKViewDelegate {
    private let device:MTLDevice
    private let pointcloudBuffer:MTLBuffer
    private let uniformsBuffer:MTLBuffer
    private let pipelineState:MTLRenderPipelineState
    private let depthPipelineState:MTLDepthStencilState
    private let commandQueue:MTLCommandQueue

    var depthTexture:MTLTexture?
    var rgbTexture:MTLTexture?
    
    // Default size for kinect depth buffer
    private var textureSize:simd_float2 = simd_float2(512.0, 424.0)
    private var numberOfVertices:Int = 512 * 424
    private var viewMatrix:matrix_float4x4 = matrix_identity_float4x4
    private var projectionMatrix:matrix_float4x4 = matrix_identity_float4x4
    private var modelTransform:matrix_float4x4 = matrix_identity_float4x4
    private var modelMatrix:matrix_float4x4 = matrix_identity_float4x4
    
    init?(with view:MTKView) {
        guard let device = view.device,
            let commandQueue = device.makeCommandQueue() else {
                print("view has no device")
                return nil
        }
        self.device = device
        self.commandQueue = commandQueue
        view.depthStencilPixelFormat = MTLPixelFormat.depth32Float

        // Create the buffer
        let pointCloudVertices = KinectRenderer.pointCloud(for: textureSize)
        let bufferLength = MemoryLayout<KinectPointCloudVertex>.size * pointCloudVertices.count
        guard let pointcloudBuffer = device.makeBuffer(bytes: pointCloudVertices,
                                                       length: bufferLength,
                                                       options: MTLResourceOptions.storageModeShared) else {
                                                        return nil
        }
        self.pointcloudBuffer = pointcloudBuffer
        print("Size of all kinect vertices = \(bufferLength)")
        print("Size of kinect vertex = \(KinectPointCloudVertex.self):\(MemoryLayout<KinectPointCloudVertex>.size)")
        print("Size of kinect uniforms = \(KinectUniforms.self):\(MemoryLayout<KinectUniforms>.size)")
        guard let uniformsBuffer = device.makeBuffer(length: MemoryLayout<KinectUniforms>.size, options: MTLResourceOptions.storageModeShared) else {
            return nil
        }
        self.uniformsBuffer = uniformsBuffer
        guard let library = device.makeDefaultLibrary() else {
            print("Failed to create default library")
            return nil
        }
        
        let vertexFunction = library.makeFunction(name: "kinectPointCloudVertexFunction")
        let fragmentFunction = library.makeFunction(name: "kinectPointCloudFragmentFunction")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "Pointcloud pipeline"
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline state \(error)")
            return nil
        }
        let depthPipelineDescriptor = MTLDepthStencilDescriptor()
        depthPipelineDescriptor.label = "Depth Pointcloud pipeline"
        depthPipelineDescriptor.depthCompareFunction = MTLCompareFunction.lessEqual
        depthPipelineDescriptor.isDepthWriteEnabled = true
        guard let depthPipelineState = device.makeDepthStencilState(descriptor: depthPipelineDescriptor) else {
            return nil
        }
        self.depthPipelineState = depthPipelineState
        let aspectRatio = Float(view.drawableSize.width / view.drawableSize.height)
        self.projectionMatrix = matrix_perspective_left_hand(65.0 * (Float.pi / 180.0), aspectRatio, 0.01, 10);
        self.viewMatrix = matrix_look_at_left_hand(simd_float3(0.5, 0.5, -2.0),
                                                   simd_float3(0.5, 0.5, 0.5),
                                                   simd_float3(0.0, 1.0, 0.0))
    }
    
    func updateUniforms() {
        var uniforms = KinectUniforms()
        let modelTransformMatrix = matrix_multiply(modelMatrix, modelTransform)
        uniforms.modelViewMatrix = matrix_multiply(viewMatrix, modelTransformMatrix)
        uniforms.projectionMatrix = projectionMatrix
        memcpy(uniformsBuffer.contents(), &uniforms, MemoryLayout.size(ofValue: uniforms))
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("CHnaging view size")
        let aspect = Float(size.width / size.height)
        projectionMatrix = matrix_perspective_left_hand(65.0 * (Float.pi / 180.0), aspect, 0.01, 10);
    }
    
    func draw(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
            let currentDrawable = view.currentDrawable,
            let renderPassDescritor = view.currentRenderPassDescriptor,
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescritor)
            else {
                print("Failed to create command buffer")
                return
        }
        updateUniforms()
        commandBuffer.label = "Command Buffer"
        renderEncoder.label = "Render Encoder"
        renderEncoder.setRenderPipelineState(self.pipelineState)
        renderEncoder.setDepthStencilState(self.depthPipelineState)
        renderEncoder.setVertexBuffer(self.pointcloudBuffer, offset: 0, index: Int(VertexInputIndexVertices.rawValue))
        renderEncoder.setVertexBuffer(self.uniformsBuffer, offset: 0, index: Int(VertexInputIndexUniforms.rawValue))
        renderEncoder.setVertexTexture(self.depthTexture, index: Int(KinectTextureIndexDepthImage.rawValue))
        renderEncoder.drawPrimitives(type: MTLPrimitiveType.point, vertexStart: 0, vertexCount: self.numberOfVertices)
        renderEncoder.endEncoding()
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }
    
    static private func pointCloud(for textureSize:simd_float2) -> [KinectPointCloudVertex] {
        let aspect: Float = textureSize.x / textureSize.y
        let pointCloudSize: simd_float2
        if aspect > 1 {
            pointCloudSize = simd_float2(1.0, 1.0 / aspect)
        } else {
            pointCloudSize = simd_float2(1.0 / aspect, 1.0)
        }
        var array = [KinectPointCloudVertex]()
        let rowPointStep = pointCloudSize.y / (textureSize.y - 1.0)
        let columnPointStep = pointCloudSize.x / (textureSize.x - 1.0)
        let texPixelWidth = 1.0 / textureSize.x
        let texPixelHeight = 1.0 / textureSize.y
        let rowTexStep = (1.0 - texPixelWidth) / (textureSize.y - 1.0)
        let columnTexStep = (1.0 - texPixelHeight) / (textureSize.x - 1.0)
        for row in 0..<Int(textureSize.y) {
            let rowPointPos = Float(row) * rowPointStep
            let rowTexCoord = (Float(row) * rowTexStep) + (texPixelHeight / 2.0)
            for column in 0..<Int(textureSize.x) {
                let columnPointPos = Float(column) * columnPointStep
                let columnTexCoord = (Float(column) * columnTexStep) + (texPixelWidth / 2.0)
                var vertex = KinectPointCloudVertex()
                vertex.position = simd_float3(rowPointPos, columnPointPos, 0.0)
                vertex.colour = simd_float3(1.0, 1.0, 1.0)
                vertex.textureCood = simd_float2(rowTexCoord, columnTexCoord)
                array.append(vertex)
            }
        }
        return array
    }
}

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
    private let pipelineState: MTLRenderPipelineState
    private let commandQueue: MTLCommandQueue

    var depthTexture:MTLTexture?
    
    // Default size for kinect depth buffer
    private var textureSize: simd_float2 = simd_float2(512.0, 424.0)
    private var numberOfVertices: UInt = 512 * 424
    
    init?(with view:MTKView) {
        guard let metalDevice = view.device,
            let metalCommandQueue = metalDevice.makeCommandQueue() else {
                print("view has no device")
                return nil
        }
        device = metalDevice
        commandQueue = metalCommandQueue
        
        // Create the buffer
        let pointCloudVertices = KinectRenderer.pointCloud(for: textureSize)
        guard let buffer = metalDevice.makeBuffer(bytes: pointCloudVertices,
                                                  length: MemoryLayout.size(ofValue: pointCloudVertices),
                                                  options: MTLResourceOptions.storageModeShared) else {
                                                    return nil
        }
        pointcloudBuffer = buffer
        guard let library = metalDevice.makeDefaultLibrary() else {
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
        do {
            pipelineState = try metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline state \(error)")
            return nil
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        
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

//
//  Renderer.swift
//  syphon-kinect-metal-client
//
//  Created by George Brown on 10.02.20.
//  Copyright © 2020 George Brown. All rights reserved.
//

import MetalKit

class Renderer <MTKViewDelegate> {
    let device:MTLDevice
    let pipelineState: MTLRenderPipelineState
    let commandQueue: MTLCommandQueue
    
    init?(with view:MTKView) {
        guard let metalDevice = view.device else {
            print("view has no device")
            return nil
        }
        device = metalDevice
        pipelineState = 
    }
}

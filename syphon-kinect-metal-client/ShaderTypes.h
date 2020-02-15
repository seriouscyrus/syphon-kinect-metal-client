//
//  ShaderTypes.c
//  syphon-kinect-metal-client
//
//  Created by George Brown on 10.02.20.
//  Copyright © 2020 George Brown. All rights reserved.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

typedef enum KinectVertexInputIndex {
    VertexInputIndexVertices = 0,
    VertexInputIndexUniforms
} VertexInputIndex;

typedef enum KinectTextureIndex {
    KinectTextureIndexDepthImage = 0,
    KinectTextureIndexRGBImage
} KinectTextureIndex;

typedef struct {
    simd_float3 position;
    simd_float3 colour;
    simd_float2 textureCood;
} KinectPointCloudVertex;

typedef struct {
    simd_float4x4 modelViewMatrix;
    simd_float4x4 projectionMatrix;
} Uniforms;

#endif

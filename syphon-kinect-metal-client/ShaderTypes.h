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

typedef enum VertexInputIndex {
    VertexInputIndexVertices = 0,
    VertexInputIndexViewportSize = 1
} VertexInputIndex;

typedef enum TextureIndex {
    TextureIndexBaseColor = 0
} TextureIndex;

typedef struct {
    vector_float3 position;
    vector_float2 textureCood;
} Vertex;

#endif

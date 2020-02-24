//
//  Shaders.metal
//  syphon-kinect-metal-client
//
//  Created by George Brown on 10.02.20.
//  Copyright © 2020 George Brown. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

#import "ShaderTypes.h"

typedef struct {
    float4 position [[ position ]];
    float4 colour;
    float2 texCoord;
    float pointSize [[ point_size ]];
} VertexOut;

vertex VertexOut kinectPointCloudVertexFunction(uint vertexID [[ vertex_id ]],
                                                constant KinectPointCloudVertex *vertices [[ buffer(VertexInputIndexVertices) ]],
                                                constant KinectUniforms &uniforms [[ buffer(VertexInputIndexUniforms) ]],
                                                texture2d<uint> depthTexture [[ texture(KinectTextureIndexDepthImage) ]]) {
    VertexOut out;
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    KinectPointCloudVertex vert = vertices[vertexID];
    
    // image format is rgba, but shader uses bgra
    const uint4 depthSample = depthTexture.sample(textureSampler, vert.textureCood).bgra;

    uint depth = depthSample.r * 255.0 + depthSample.g;
    float adjustedDepth = (float)depth / 5000.0;
    float4 adjustedPosition = float4(vert.position.x, vert.position.y, adjustedDepth, 1.0);
    float4 colour = float4(vert.colour.rgb, 1.0);
    if (depthSample.b != 0.0) {
        colour = float4(1.0, 1.0, 1.0, 1.0);
        out.pointSize = 2.0;
    } else {
        colour = float4(0.3, 0.3, 0.3, 1.0);
        out.pointSize = 2.0;
    }
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * adjustedPosition;
    out.colour = colour;
    out.texCoord = vert.textureCood;
    return out;
}

// Fragment function
fragment float4
kinectPointCloudRGBFragmentFunction(VertexOut in [[stage_in]],
               texture2d<half> colorTexture [[ texture(KinectTextureIndexRGBImage) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    // Sample the texture to obtain a color
    const half4 colorSample = colorTexture.sample(textureSampler, in.texCoord);

    // We return the color of the texture
    return float4(colorSample);
}

fragment float4
kinectPointCloudFragmentFunction(VertexOut in [[stage_in]])
{


    // We return the color of the texture
    return float4(in.colour);
}

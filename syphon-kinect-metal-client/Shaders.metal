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
                                                texture2d<half> depthTexture [[ texture(KinectTextureIndexDepthImage) ]]) {
    VertexOut out;
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    KinectPointCloudVertex vert = vertices[vertexID];
    // Sample the texture to obtain a color
    const half4 depthSample = depthTexture.sample(textureSampler, vert.textureCood);
    //int rcomp = (int)(depthSample.r * 255);
    //int gcomp = (int)(depthSample.g * 255);
    float depth = (depthSample.r * 255) * 32.0 + (depthSample.g * 255);
    //int intDepth = rcomp * 32 + gcomp;
    float normalised = depth / (255 * 32 + 255);
    float4 adjustedPosition = float4(vert.position.x, vert.position.y, normalised * 10.0, 1.0);
    float4 colour = float4(vert.colour.rgb, 1.0);
    if (depthSample.b != 0.0) {
        colour = float4(1.0, 0.0, 0.0, 1.0);
    } else {
        colour = float4(0.0, 0.0, 0.0, 0.0);
    }
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * adjustedPosition;
    out.colour = colour;
    out.texCoord = vert.textureCood;
    out.pointSize = 1.0;
    return out;
}

// Fragment function
//fragment float4
//kinectPointCloudFragmentFunction(VertexOut in [[stage_in]],
//               texture2d<half> colorTexture [[ texture(KinectTextureIndexRGBImage) ]])
//{
//    constexpr sampler textureSampler (mag_filter::linear,
//                                      min_filter::linear);
//
//    // Sample the texture to obtain a color
//    const half4 colorSample = colorTexture.sample(textureSampler, in.texCoord);
//
//    // We return the color of the texture
//    return float4(colorSample);
//}

fragment float4
kinectPointCloudFragmentFunction(VertexOut in [[stage_in]])
{


    // We return the color of the texture
    return float4(in.colour);
}

//
//  Shader.metal
//  Demo
//
//  Created by mac on 2017/9/28.
//  Copyright © 2017年 com.cmcm. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
// 输入的顶点和纹理坐标
struct VertexIn
{
    packed_float3 position;
    packed_float2 st;
};
// 输出顶点和纹理坐标，因为需要渲染纹理，可以不用输入顶点颜色
struct VertexOut
{
    float4 position [[position]];
    float2 st;
};
// 添加纹理顶点坐标
vertex VertexOut texture_vertex(uint vid[[vertex_id]], const device VertexIn *vertex_array[[buffer(0)]])
{
    VertexOut outVertex;
    VertexIn vertexIn = vertex_array[vid];
    outVertex.position = float4(vertexIn.position, 1.0);
    outVertex.st = vertexIn.st;
    //    outVertex.color = color[vid];
    return outVertex;
};

fragment float4 texture_fragment(VertexOut inFrag[[stage_in]], texture2d<float> texas[[texture(0)]])
{
    constexpr sampler defaultSampler;
    float4 rgba = texas.sample(defaultSampler, inFrag.st).rgba;
    return rgba;
};





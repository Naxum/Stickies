//
//  Shaders.metal
//  Stickies
//
//  Created by Jacob Sawyer on 7/22/17.
//  Copyright © 2017 Jake Sawyer. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
	packed_float3 position;
	packed_float2 texcoord;
};

struct Stamp {
	float4x4 matrix;
	float4 color;
};

struct VertexOut {
	float4 position [[ position ]];
	float4 color;
	float2 texcoord;
};

constexpr sampler s = sampler(coord::normalized,
							  address::clamp_to_zero,
							  filter::linear);

vertex VertexOut pass_vertex(const device VertexIn* v_in [[ buffer(0) ]],
							 const device Stamp* stamp [[ buffer(1) ]],
						     uint v_id [[ vertex_id ]],
							 uint i_id [[ instance_id ]]) {
	VertexOut out;
	out.position = stamp[i_id].matrix * float4(v_in[v_id].position, 1);
	out.color = stamp[i_id].color;
	out.texcoord = v_in[v_id].texcoord;
	return out;
}

fragment half4 render_vertex(VertexOut v_out [[ stage_in ]],
							 texture2d<float, access::sample> texture [[ texture(0) ]]) {
	return half4(v_out.color.r, v_out.color.g, v_out.color.b, v_out.color.a * texture.sample(s, v_out.texcoord).r + 0.1);
}

// old
//vertex float4 basic_vertex(const device packed_float3* vertex_array [[ buffer(0) ]],
//						   unsigned int vid [[ vertex_id ]]) {
//	return float4(vertex_array[vid], 1.0);
//}
//
//fragment half4 basic_fragment() {
//	return half4(1.0, 1.0, 1.0, 1.0);
//}


//--------------------------------------------------------------------------------
//
//	Redistribution and use in source and binary forms, with or without
//	modification, are permitted provided that the following conditions are met :
//
//	*Redistributions of source code must retain the above copyright notice, this
//	list of conditions and the following disclaimer.
//
//	* Redistributions in binary form must reproduce the above copyright notice,
//	this list of conditions and the following disclaimer in the documentation
//	and/or other materials provided with the distribution.
//	
//	* Neither the name of the copyright holder nor the names of its
//	contributors may be used to endorse or promote products derived from
//	this software without specific prior written permission.
//	
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//	DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//	FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//	DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//	OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//	OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 
// Copyright(c) 2019, Sergen Eren
// All rights reserved.
//----------------------------------------------------------------------------------
// 
//	Version 1.0: Sergen Eren, 02/11/2019
//
// File: Kernels to calculate and load the procedural sky value and cdf textures
//
//-----------------------------------------------

#define _USE_MATH_DEFINES
#include <cmath>
#include <stdio.h>
#include <float.h>

// Cuda includes
#include <cuda_runtime.h> 
#include <curand_kernel.h>
#include <device_launch_parameters.h>
#include "helper_math.h"


// Internal includes
#include "kernel_params.h"

#define INV_2_PI		1.0f / (2.0f * M_PI) 
#define INV_4_PI		1.0f / (4.0f * M_PI) 
#define INV_PI			1.0f / M_PI 


extern "C" __global__ void glow(const Kernel_params kernel_params, float treshold , const int width, const int height) {


	int x = blockIdx.x * blockDim.x + threadIdx.x;
	int y = blockIdx.y * blockDim.y + threadIdx.y;
	if (x >= width || y >= height) return;
	const unsigned int idx = y * width + x;

	// Do gaussian blur and add glow effect to display buffer 

	float sigma = 1.0f;
	float rho, s = 2.0f * sigma * sigma;
	float3 sum;
	float3 val = make_float3(.0f); 

	for (int i = -2; i <= 2; ++i) {
		for (int j = -2; j <= 2; ++j) {
			rho = sqrtf(i*i + j*j);
			float weight = (expf(-(rho * rho) / s)) / (M_PI * s);
			int kernel_idx = ((y + j) * width) + (x + i);
			kernel_idx = clamp(kernel_idx, 0, width*height);
			val += make_float3(kernel_params.raw_buffer[kernel_idx]) * weight;

		}
	}

	if (length(val) < treshold) val = make_float3(.0f);

	kernel_params.raw_buffer[idx] += make_float4(val);

}
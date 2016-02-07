//
//  kernels.cl
//  Mandelbrot2
//
//  Created by Palle Klewitz on 16.08.14.
//  Copyright (c) 2014 - 2016 Palle Klewitz.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is furnished
//  to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#pragma OPENCL EXTENSION cl_khr_fp64 : enable

typedef struct
{
	double real;
	double imag;
} cplx_double;

inline cplx_double cplx_square(cplx_double value)
{
	cplx_double result;
	result.real = value.real * value.real - value.imag * value.imag;
	result.imag = 2.0 * value.real * value.imag;
	return result;
}

inline cplx_double cplx_add(cplx_double v1, cplx_double v2)
{
	v1.real += v2.real;
	v1.imag += v2.imag;
	return v1;
}

inline cplx_double cplx_sub(cplx_double v1, cplx_double v2)
{
	v1.real -= v2.real;
	v1.imag -= v2.imag;
	return v2;
}

inline cplx_double cplx_mul(cplx_double v1, cplx_double v2)
{
	cplx_double result;
	result.real = v1.real * v2.real - v1.imag * v2.imag;
	result.imag = v1.real * v2.imag + v1.imag * v2.real;
	return result;
}

inline cplx_double cplx_div(cplx_double v1, cplx_double v2)
{
	cplx_double result;
	double divisor = v2.real * v2.real + v2.imag * v2.imag;
	result.real = (v1.real * v2.real + v1.imag * v2.imag) / divisor;
	result.imag = (v1.imag * v2.real - v1.real * v2.imag) / divisor;
	return result;
}

inline double cplx_abs_squared(cplx_double value)
{
	return value.real * value.real + value.imag * value.imag;
}

inline float4 get_color(uint iteration, uint iterations, float factor, float shift, cplx_double z, unsigned char color_scaling, unsigned char smooth_colors)
{
	float alpha;
	if (smooth_colors)
		alpha = (float) (iteration - native_log2(native_log((float)(cplx_abs_squared(z)))));
	else
		alpha = (float) iteration;
	
	if (color_scaling == 0)
		alpha /= (float)iterations;
	else if (color_scaling == 1)
		alpha = native_log(alpha);
	else if (color_scaling == 2)
		alpha = 1.0f / (alpha + 1.0f);
	else if (color_scaling == 3)
		alpha = native_sqrt(alpha);
	alpha *= 3.1415926536f * factor;
	alpha += shift;
	float red = native_cos(alpha);
	float blue = native_sin(-alpha);
	float green = (red + blue) * 0.667f;
	return (float4)(red, green, blue, 1);
}


kernel void mandelbrot(__write_only image2d_t output, const double sizeX, const double sizeY, const int image_width, const int image_height, const double shiftX, const double shiftY, const uint iterations, const float colorFactor, const float colorShift, unsigned char color_mode, unsigned char smooth_colors, unsigned char color_scaling)
{
	int2 pixel = (int2)(get_global_id(0), get_global_id(1));
	int2 size = (int2)(image_width, image_height);
	cplx_double position = {(double)pixel.x * sizeX / (double) size.x + shiftX - sizeX * 0.5, (double)pixel.y * sizeY / (double)size.y + shiftY - sizeY * 0.5};
	cplx_double z = position;
	
	float4 color = (float4)(0,0,0,2);
	for (uint i = 0; i < iterations; i++)
	{
		z = cplx_add(cplx_square(z), position);
		if (cplx_abs_squared(z) > 4.0)
		{
			if (color_mode != 1)
				color = get_color(i, iterations, colorFactor, colorShift, z, color_scaling, smooth_colors);
			i = iterations;
		}
	}
	if (color_mode != 0)
	{
		if (color.w == 2.0f)
		{
			float c = z.imag / z.real;
			float r = atan(c) * 2;
			float a = 1.0 / (native_sqrt((float)(cplx_abs_squared(z)) * 0.5f + 1.0f));
			
			color.w = 1.0;
			color.x = native_cos(r) * a;
			color.y = native_sin(r) * a;
			color.z = -native_cos(r) * a;
		}
	}
	else
		color.w = 1.0f;
	write_imagef(output, pixel, color);
}

kernel void reset(__write_only image2d_t texture)
{
    float4 clear = (float4)(0);
    int2 pixel = (int2)(get_global_id(0), get_global_id(1));
    write_imagef(texture, pixel, clear);
    
}

#pragma OPENCL EXTENSION cl_khr_fp64 : enable

//FLOAT128 LOW LEVEL MATH
/*
inline uint4 float128(double value)
{
	uint4 result = (uint4)(0);
	double fractional;
	result.x = (uint) modf(value, &fractional);
	value = fractional * 4294967296.0;
	result.y = (uint) modf(value, &fractional);
	value = fractional * 4294967296.0;
	result.z = (uint) modf(value, &fractional);
	value = fractional * 4294967296.0;
	result.w = (uint) modf(value, &fractional);
	return result;
}
*/
/*
// Increment U
inline uint4 inc128(uint4 u)
{
	// Compute all carries to add
	int4 h = (u == (uint4)(0xFFFFFFFF)); // Note that == sets ALL bits if true [6.3.d]
	uint4 c = (uint4)(h.y&h.z&h.w&1,h.z&h.w&1,h.w&1,1);
	return u+c;
}

// Return -U
inline uint4 neg128(uint4 u)
{
	return inc128(u ^ (uint4)(0xFFFFFFFF)); // (1 + ~U) is two's complement
}

// Return U+V
inline uint4 add128(uint4 u,uint4 v)
{
	uint4 s = u+v;
	uint4 h = (uint4)(s < u);
	uint4 c1 = h.yzwx & (uint4)(1,1,1,0); // Carry from U+V
	h = (uint4)(s == (uint4)(0xFFFFFFFF));
	uint4 c2 = (uint4)((c1.y|(c1.z&h.z))&h.y,c1.z&h.z,0,0); // Propagated carry
	return s+c1+c2;
}

// Return U<<1
inline uint4 shl128(uint4 u)
{
	uint4 h = (u>>(uint4)(31)) & (uint4)(0,1,1,1); // Bits to move up
	return (u<<(uint4)(1)) | h.yzwx;
}

// Return U>>1
inline uint4 shr128(uint4 u)
{
	uint4 h = (u<<(uint4)(31)) & (uint4)(0x80000000,0x80000000,0x80000000,0); // Bits to move down
	return (u>>(uint4)(1)) | h.wxyz;
}

// Return U*K.
// U MUST be positive.
inline uint4 mul128u(uint4 u,uint k)
{
	uint4 s1 = u * (uint4)(k);
	uint4 s2 = (uint4)(mul_hi(u.y,k),mul_hi(u.z,k),mul_hi(u.w,k),0);
	return add128(s1,s2);
}

// Return U*V truncated to keep the position of the decimal point.
// U and V MUST be positive.
inline uint4 mulfpu(uint4 u,uint4 v)
{
	// Diagonal coefficients
	uint4 s = (uint4)(u.x*v.x,mul_hi(u.y,v.y),u.y*v.y,mul_hi(u.z,v.z));
	// Off-diagonal
	uint4 t1 = (uint4)(mul_hi(u.x,v.y),u.x*v.y,mul_hi(u.x,v.w),u.x*v.w);
	uint4 t2 = (uint4)(mul_hi(v.x,u.y),v.x*u.y,mul_hi(v.x,u.w),v.x*u.w);
	s = add128(s,add128(t1,t2));
	t1 = (uint4)(0,mul_hi(u.x,v.z),u.x*v.z,mul_hi(u.y,v.w));
	t2 = (uint4)(0,mul_hi(v.x,u.z),v.x*u.z,mul_hi(v.y,u.w));
	s = add128(s,add128(t1,t2));
	t1 = (uint4)(0,0,mul_hi(u.y,v.z),u.y*v.z);
	t2 = (uint4)(0,0,mul_hi(v.y,u.z),v.y*u.z);
	s = add128(s,add128(t1,t2));
	// Add 3 to compensate truncation
	return add128(s,(uint4)(0,0,0,3));
}

// Return U*U truncated to keep the position of the decimal point.
// U MUST be positive.
inline uint4 sqrfpu(uint4 u)
{
	// Diagonal coefficients
	uint4 s = (uint4)(u.x*u.x,mul_hi(u.y,u.y),u.y*u.y,mul_hi(u.z,u.z));
	// Off-diagonal
	uint4 t = (uint4)(mul_hi(u.x,u.y),u.x*u.y,mul_hi(u.x,u.w),u.x*u.w);
	s = add128(s,shl128(t));
	t = (uint4)(0,mul_hi(u.x,u.z),u.x*u.z,mul_hi(u.y,u.w));
	s = add128(s,shl128(t));
	t = (uint4)(0,0,mul_hi(u.y,u.z),u.y*u.z);
	s = add128(s,shl128(t));
	// Add 3 to compensate truncation
	return add128(s,(uint4)(0,0,0,3));
}


*/
typedef struct
{
	double real;
	double imag;
} cplx_double;
/*
typedef struct
{
	quad real;
	quad imag;
} cplx_quad;
*/

typedef struct
{
	uint4 real;
	uint4 imag;
} cplx_float128;

inline cplx_double cplx_sqare(cplx_double value)
{
	cplx_double result;
	result.real = value.real * value.real - value.imag * value.imag;
	result.imag = 2.0 * value.real * value.imag;
	return result;
}

inline cplx_float128 cplx_sqare128(cplx_float128 value)
{
	cplx_float128 result;
	result.real = add128(sqrfpu(value.real), neg128(sqrfpu(value.imag)));
	result.imag = mulfpu(mulfpu((uint4)(2,0,0,0), value.real), value.imag);
	return result;
}

inline cplx_double cplx_add(cplx_double v1, cplx_double v2)
{
	v1.real += v2.real;
	v1.imag += v2.imag;
	return v1;
}

inline cplx_float128 cplx_add128(cplx_float128 v1, cplx_float128 v2)
{
	v1.real = add128(v1.real, v2.real);
	v1.imag = add128(v1.imag, v2.imag);
	return v1;
}

inline double cplx_abs_squared(cplx_double value)
{
	return value.real * value.real + value.imag * value.imag;
}

inline uint4 cplx_abs_squared128(cplx_float128 value)
{
	return add128(sqrfpu(value.real), sqrfpu(value.imag));
}

inline float4 get_color(uint iteration, uint iterations, float factor, float shift)
{
	float alpha = (float) iteration / iterations * 3.1415926536f * factor + shift;
	float red = native_cos(alpha);
	float blue = native_sin(-alpha);
	float green = (red + blue) * 0.667f;
	return (float4)(red, green, blue, 1);
}

kernel void mandelbrot(__write_only image2d_t output, const double sizeX, const double sizeY, const int image_width, const int image_height, const double shiftX, const double shiftY, const uint iterations, const float colorFactor, const float colorShift)
{
	int2 pixel = (int2)(get_global_id(0), get_global_id(1));
	int2 size = (int2)(image_width, image_height);
	cplx_double position = {(double)pixel.x * sizeX / (double) size.x + shiftX - sizeX * 0.5, (double)pixel.y * sizeY / (double)size.y + shiftY - sizeY * 0.5};
	cplx_double z = position;
	
	float4 color = (float4)(0,0,0,0);
	for (uint i = 0; i < iterations; i++)
	{
		z = cplx_add(cplx_sqare(z), position);
		if (cplx_abs_squared(z) > 4)
		{
			color = get_color(i, iterations, colorFactor, colorShift);
			i = iterations;
		}
	}
	write_imagef(output, pixel, color);
}
/*
kernel void mandelbrot128(__write_only image2d_t output, const double sizeX, const double sizeY, const int image_width, const int image_height, const double shiftX, const double shiftY, const uint iterations, const float colorFactor, const float colorShift)
{
	int2 pixel = (int2)(get_global_id(0), get_global_id(1));
	int2 size = (int2)(image_width, image_height);
	cplx_float128 position = {float128((double)pixel.x * sizeX / (double) size.x + shiftX - sizeX * 0.5), float128((double)pixel.y * sizeY / (double)size.y + shiftY - sizeY * 0.5)};
	cplx_float128 z = position;
	float4 color = (float4)(0,0,0,0);
	for (uint i = 0; i < iterations; i++)
	{
		z = cplx_add128(cplx_sqare128(z), position);
		if (cplx_abs_squared128(z).x > 4)
		{
			color = get_color(i, iterations, colorFactor, colorShift);
			i = iterations;
		}
	}
	write_imagef(output, pixel, color);
}
*/
kernel void reset(__write_only image2d_t texture)
{
	float4 clear = (float4)(0);
	int2 pixel = (int2)(get_global_id(0), get_global_id(1));
	write_imagef(texture, pixel, clear);
	
}


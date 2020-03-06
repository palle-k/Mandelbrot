//
//  CLMandelbrotView.m
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

#import "CLMandelbrotView.h"
#import "kernels.cl.h"
#include <sys/types.h>
#include <sys/sysctl.h>

@implementation CLMandelbrotView

@synthesize progress = _progress;

#pragma mark - Tiling


cl_int2 NthTilePosition(unsigned int n, int tilesX, int tilesY)
{
	n = tilesX * tilesY - 1 - n;
	cl_int2 tilePosition;
	tilePosition.x = n % tilesX;
	tilePosition.y = n / tilesX;
	return tilePosition;
}

cl_int2 NthTilePositionFromCenter(unsigned int n, int tilesX, int tilesY)
{
	cl_int2 tilePosition = { .x = 0, .y = 0 };
	
	int centerX = tilesX / 2;
	int centerY = tilesY / 2;
	
	int dx = 0;
	int dy = -1;
	
	int maxR = MAX(tilesX, tilesY) / 2;
	int i = 0;
	
	for (int r = 0; r < maxR; r++)
	{
		int stepX = r;
		int stepY = r;
		int maxSteps = MAX((r*2+1)*2+(r*2-1)*2, 1);
		for (int step = 0; step < maxSteps; step++)
		{
			if ((stepX + centerX >= 0 && stepX + centerX < tilesX) &&  (stepY + centerY >= 0 && stepY + centerY < tilesY))
			{
				if (i == n)
				{
					r = maxR;
					step = maxSteps;
					tilePosition.x = stepX + centerX;
					tilePosition.y = stepY + centerY;
					break;
				}
				i++;
			}
			stepX += dx;
			stepY += dy;
			
			if (stepX == -stepY || stepX == stepY)
			{
				int c = dx;
				dx = dy;
				dy = -c;
			}
			
		}
	}
	
	return tilePosition;
}

#pragma mark - Initialization

- (instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self)
	{
        cl_block = NULL;
	}
	return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if (self)
	{
		cl_block = NULL;
	}
	return self;
}

- (void) setup
{
	[self initParameters];
	[self initCL];
	[self initMainTexture];
	[self initPreviewTextureWithFactor:8];
	if (!_disableAutomaticUpdates)
		[self updateCL];
}

- (void) initParameters
{
	zoom = 1;
	previewZoom = 1;
	shift.x = -0.5;
	shift.y = 0;
	iterations = 256;
	color_shift = 2;
	color_factor = 16;
	renderID = 0;
	smooth_coloring = 0;
	color_scale = 0;
	devicePixelRatio = [self.window.screen backingScaleFactor];
	_progress = [[NSProgress alloc] init];
}

- (void) initCL
{
	if(initialized)
		return;
	width = self.frame.size.width * devicePixelRatio * 2;
	height = self.frame.size.height * devicePixelRatio * 2;
	usePreview = NO;
	
	[self.openGLContext makeCurrentContext];
	gcl_gl_set_sharegroup(CGLGetShareGroup(CGLGetCurrentContext()));
	
    cl_uint num = 0;
    clGetDeviceIDs(NULL,CL_DEVICE_TYPE_GPU, 0, NULL, &num);
    
    NSLog(@"Devices: %u", num);
     
    cl_device_id devices[num];
    clGetDeviceIDs(NULL,CL_DEVICE_TYPE_GPU, num, devices, NULL);
    
	cl_queue = gcl_create_dispatch_queue(CL_DEVICE_TYPE_USE_ID, devices[num - 1]);
    if (cl_block == NULL) {
        cl_block = dispatch_semaphore_create(0);
    }
	
	char name[128];
	cl_device_id gpu = gcl_get_device_id_with_dispatch_queue(cl_queue);
	clGetDeviceInfo(gpu, CL_DEVICE_NAME, 128, name, NULL);
	fprintf(stdout, "Created a dispatch queue using the %s\n", name);
	
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_TEXTURE_2D);
	glMatrixMode(GL_PROJECTION);
	glViewport(0, 0, self.bounds.size.width * devicePixelRatio, self.bounds.size.height * devicePixelRatio);
	glOrtho(-1.0f, 1.0f, -1.0f, 1.0f, -1.0f, 1.0f);
	
	initialized = YES;
}

#pragma mark - Texture Initialization

- (void) initMainTexture
{
	glGenTextures(1, &mainTexture);
	glBindTexture(GL_TEXTURE_2D, mainTexture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	// glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP_SGIS, GL_TRUE);
	glTexImage2D(GL_TEXTURE_2D, 0, 4, width * 2, height * 2, 0, GL_RGBA, GL_UNSIGNED_INT, NULL);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	// glTexParameterf (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	mainImage = gcl_gl_create_image_from_texture(GL_TEXTURE_2D, 0, mainTexture);
	mainTextureAvailable = YES;
	
}

- (void) initPreviewTextureWithFactor: (int) downscaling
{
	downscaling *= devicePixelRatio;
	previewWidth = width / downscaling;
	previewHeight = height / downscaling;
	glGenTextures(1, &previewTexture);
	glBindTexture(GL_TEXTURE_2D, previewTexture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexImage2D(GL_TEXTURE_2D, 0, 4, previewWidth, previewHeight, 0, GL_RGBA, GL_UNSIGNED_INT, NULL);
	previewImage = gcl_gl_create_image_from_texture(GL_TEXTURE_2D, 0, previewTexture);
	previewTextureAvailable = YES;
}

#pragma mark Teardown

- (void) dealloc
{
	[self teardown];
}

- (void) teardown
{
	if(!initialized)
		return;
	initialized = NO;
	mainTextureAvailable = NO;
	previewTextureAvailable = NO;
	glDeleteTextures(1, &mainTexture);
	glDeleteTextures(1, &previewTexture);
}

#pragma mark - Rendering

- (void) updateCL
{
	updating = YES;
	
	if(!mainTextureAvailable)
		usePreview = YES;
	if(usePreview && !previewTextureAvailable)
		return;
	
	[self.progressDelegate mandelbrotViewDidChangeSetup:self];
	
	dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0),
	^{
		double sizeX = 2.0 / zoom * width / height;
		double sizeY = 2.0 / zoom;
		
		if (iterations <= 131072)
		{
			dispatch_async(cl_queue,
						   ^{
							   cl_ndrange range =
							   {
								   2,
								   {0,0},
								   {previewWidth, previewHeight},
								   {0, 0}
							   };
							   mandelbrot_kernel(&range, previewImage, sizeX, sizeY, previewWidth, previewHeight, shift.x, shift.y, iterations, color_factor, color_shift, color_mode, smooth_coloring, color_scale);
							   dispatch_semaphore_signal(cl_block);
						   });
			dispatch_semaphore_wait(cl_block, DISPATCH_TIME_FOREVER);
			dispatch_sync(dispatch_get_main_queue(),
						  ^{
							  [self drawRect:self.frame];
						  });
			if (usePreview)
				updating = NO;
		}
		
		if (!usePreview)
		{
			int baseTiles = 2;
			if(iterations >= 4194304)
				baseTiles = 128;
			else if(iterations >= 1048576)
				baseTiles = 96;
			else if(iterations >= 524288)
				baseTiles = 64;
			else if(iterations >= 131072)
				baseTiles = 48;
			else if(iterations >= 32768)
				baseTiles = 32;
			else if(iterations >= 8192)
				baseTiles = 16;
			else if (iterations >= 4096)
				baseTiles = 8;
			else if (iterations >= 256)
				baseTiles = 4;
			
			if (_optimizeSpeed)
			{
				baseTiles = 2;
				if(iterations >= 4194304)
					baseTiles = 64;
				else if(iterations >= 1048576)
					baseTiles = 32;
				else if(iterations >= 524288)
					baseTiles = 24;
				else if(iterations >= 131072)
					baseTiles = 16;
				else if(iterations >= 32768)
					baseTiles = 12;
				else if(iterations >= 8192)
					baseTiles = 8;
				else if (iterations >= 4096)
					baseTiles = 4;
			}
			
			int tilesX = (int)((double) baseTiles * width / height);
			int tilesY = baseTiles;
			
			dispatch_sync(dispatch_get_main_queue(),
			^{
				_progress = [[NSProgress alloc] init];
				_progress.totalUnitCount = tilesX * tilesY;
				_progress.completedUnitCount = 0;
			});
			
			dispatch_sync(cl_queue,
			^{
				cl_ndrange range =
				{
					2,
					{0, 0},
					{width, height},
					{0, 0}
				};
				reset_kernel(&range, mainImage);
			});
			
			mainTextureInvalid = NO;
			renderID++;
			int currentRenderID = renderID;
			for (int i = tilesY - 1; i >= 0; i--)
			{
				if(usePreview || renderID != currentRenderID)
					break;
				for (int j = 0; j < tilesX; j++)
				{
					if(usePreview || renderID != currentRenderID)
						break;
					
					cl_int2 tilePosition = NthTilePosition(j + i * tilesX, tilesX, tilesY);
					
					dispatch_sync(cl_queue,
					^{
						cl_ndrange range =
						{
							2,
							{width / tilesX * tilePosition.x, height / tilesY * tilePosition.y},
							{(width / tilesX), (height / tilesY)},
                            {0, 0}
						};
						mandelbrot_kernel(&range, mainImage, sizeX, sizeY, width, height, shift.x, shift.y, iterations, color_factor, color_shift, color_mode, smooth_coloring, color_scale);
					});
					
					dispatch_sync(dispatch_get_main_queue(),
					^{
						_progress.completedUnitCount++;
						[_progressDelegate mandelbrotView:self didUpdateProgress:_progress];
						[self drawRect:self.bounds];
					});
				}
			}
			dispatch_sync(dispatch_get_main_queue(), ^{_progress.completedUnitCount = _progress.totalUnitCount;});
			if (renderID == currentRenderID)
				updating = NO;
			dispatch_sync(dispatch_get_main_queue(),
			^{
				if (renderID == currentRenderID)
				{
					_progress.completedUnitCount = _progress.totalUnitCount;
					[_progressDelegate mandelbrotView:self didUpdateProgress:_progress];
				}
				[self drawRect:self.frame];
			});
			if (renderID == currentRenderID)
				[self.delegate mandelbrotViewDidFinishRendering:self];
		}
	});
}

+ (NSString *)machineModel
{
    size_t len = 0;
    sysctlbyname("hw.model", NULL, &len, NULL, 0);
    if (len) {
        char *model = malloc(len * sizeof(char));
        sysctlbyname("hw.model", model, &len, NULL, 0);
        NSString *model_ns = [NSString stringWithUTF8String:model];
        free(model);
        return model_ns;
    }

    return @"unknown";
}

- (void)drawRect:(NSRect)dirtyRect
{
	[self.openGLContext makeCurrentContext];

	glClear(GL_COLOR_BUFFER_BIT);
	glDisable(GL_DEPTH_TEST);
	if(!initialized)
		return;
	glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
	
	if (updating || usePreview)
	{
		glBindTexture(GL_TEXTURE_2D, previewTexture);
		glBegin(GL_QUADS);
		{
			glTexCoord2d(0.0f, 0.0f);
			glVertex2f(-1.0f, -1.0f);
			
			glTexCoord2d(1.0f, 0.0f);
			glVertex2f(1.0f, -1.0f);
			
			glTexCoord2d(1.0f, 1.0f);
			glVertex2f(1.0f, 1.0f);
			
			glTexCoord2d(0.0f, 1.0f);
			glVertex2f(-1.0f, 1.0f);
		}
		glEnd();
	}
	
	glBindTexture(GL_TEXTURE_2D, mainTexture);
	// glGenerateMipmap(GL_TEXTURE_2D);
    // glBindTexture(GL_TEXTURE_2D, previewTexture);
    
    float texture_scale = 1.0f / 2.0f;
    
	if (usePreview && !mainTextureInvalid)
	{
		double relativeZoom = zoom / previewZoom;

		if (relativeZoom < 32)
		{
			double relativeShiftX = (previewShift.x - shift.x) * zoom * height / width;
			double relativeShiftY = (previewShift.y - shift.y) * zoom;
			
			glBegin(GL_QUADS);
			{
                glTexCoord2d(0, 0);
				glVertex2f(-1.0f * relativeZoom + relativeShiftX, -1.0f * relativeZoom + relativeShiftY);
				
                glTexCoord2d(texture_scale, 0);
				glVertex2f(1.0f * relativeZoom + relativeShiftX, -1.0f * relativeZoom + relativeShiftY);
				
                glTexCoord2d(texture_scale, texture_scale);
				glVertex2f(1.0f * relativeZoom + relativeShiftX, 1.0f * relativeZoom + relativeShiftY);
				
                glTexCoord2d(0, texture_scale);
				glVertex2f(-1.0f * relativeZoom + relativeShiftX, 1.0f * relativeZoom + relativeShiftY);
			}
			glEnd();
		}
	}
	else if (!usePreview)
	{
		glBegin(GL_QUADS);
		{
			glTexCoord2d(0, 0);
			glVertex2f(-1, -1);
			
			glTexCoord2d(texture_scale, 0);
			glVertex2f(1, -1);
			
			glTexCoord2d(texture_scale, texture_scale);
			glVertex2f(1, 1);
            
			glTexCoord2d(0, texture_scale);
			glVertex2f(-1, 1);
		}
		glEnd();
	}
	
	if (usePreview)
	{
		glDisable(GL_TEXTURE_2D);
		glColor4f(1, 1, 1, 1);
		glLineWidth(1 / devicePixelRatio);
		glBegin(GL_LINES);
		{
			glVertex2f(-1.0, 0.0);
			glVertex2f(1.0, 0.0);
			
			glVertex2f(0.0, -1.0);
			glVertex2f(0.0, 1.0);
		}
		glEnd();
		glEnable(GL_TEXTURE_2D);
	}
	
	glFinish();
}

#pragma mark - Window Events

- (void)reshape
{
	[super reshape];
	
	renderID++;
	[self teardown];
	
	devicePixelRatio = [self.window.screen backingScaleFactor];
	lastChangeTime = CACurrentMediaTime();
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(),
	^{
		//NSLog(@"change time delta: %f", CACurrentMediaTime() - lastChangeTime);
		if(CACurrentMediaTime() - lastChangeTime >= 0.5)
		{
			[self.openGLContext makeCurrentContext];
			[self.openGLContext update];
			[self initCL];
			[self initPreviewTextureWithFactor:8];
			[self initMainTexture];
			glMatrixMode(GL_PROJECTION);
			glViewport(0, 0, self.bounds.size.width * devicePixelRatio, self.bounds.size.height * devicePixelRatio);
			glOrtho(-1, 1, -1, 1, -1, 1);
			usePreview = NO;
			if (!_disableAutomaticUpdates)
				[self updateCL];
		}
	});
}

#pragma mark - Control methods

- (void)usePreviewMode:(BOOL)enable
{
	usePreview = enable;
	previewZoom = zoom;
	previewShift.x = shift.x;
	previewShift.y = shift.y;
	if (!_disableAutomaticUpdates)
		[self updateCL];
}

- (double)zoom
{
	return zoom;
}

- (void)setZoom:(double)newZoom
{
	zoom = newZoom;
	if(!(updating && usePreview) && !_disableAutomaticUpdates)
		[self updateCL];
}

- (void)shiftBy:(CGVector) pixels
{
	shift.x -= pixels.dx / self.bounds.size.height * 2.0 / zoom;
	shift.y -= pixels.dy / self.bounds.size.height * 2.0 / zoom;
	if(!updating && !_disableAutomaticUpdates)
		[self updateCL];
}

- (unsigned int)iterations
{
	return iterations;
}

- (void)setIterations:(unsigned int)newIterations
{
	iterations = newIterations;
	if(iterations >= 8192 && width / previewWidth <= 16 * devicePixelRatio)
	{
		glDeleteTextures(1, &previewTexture);
		[self initPreviewTextureWithFactor:16];
	}
	else if (iterations < 8192 && width / previewWidth > 16 * devicePixelRatio)
	{
		glDeleteTextures(1, &previewTexture);
		[self initPreviewTextureWithFactor:8];
	}
	mainTextureInvalid = YES;
	if (!_disableAutomaticUpdates)
		[self updateCL];
}

- (double)color_shift
{
	return color_shift;
}

- (void)setColor_shift:(double)new_color_shift
{
	color_shift = new_color_shift;
	mainTextureInvalid = YES;
	if (!_disableAutomaticUpdates)
		[self updateCL];
}

- (double)color_factor
{
	return color_factor;
}

- (void)setColor_factor:(double)new_color_factor
{
	color_factor = new_color_factor;
	mainTextureInvalid = YES;
	if (!_disableAutomaticUpdates)
		[self updateCL];
}

#pragma mark - Snapshotting

- (GLubyte *)getSnapshot:(size_t *)length
{
	[self.openGLContext makeCurrentContext];
	glBindTexture(GL_TEXTURE_2D, mainTexture);
	
	*length = width * height * 4;
	
	GLubyte *buffer = (GLubyte *) malloc(width * height * 4);
	glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
	
	return buffer;
}

- (NSBitmapImageRep *)getShnapshot
{
	size_t bitmap_size;
	GLubyte *snapshotData = [self getSnapshot:&bitmap_size];
	
	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&snapshotData pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:width * 4 bitsPerPixel:32];
	
	free(snapshotData);
	
	return bitmap;
}

- (CGSize)textureSize
{
	return CGSizeMake(width, height);
}

- (cl_double2)shift
{
	return shift;
}

- (void)setShift:(cl_double2)newShift
{
	shift = newShift;
	if (!_disableAutomaticUpdates)
		[self updateCL];
}

- (unsigned char)color_mode
{
	return color_mode;
}

- (void)setColor_mode:(unsigned char)newMode
{
	color_mode = newMode;
	if (!_disableAutomaticUpdates)
		[self updateCL];
}

- (unsigned char)smooth_coloring
{
	return smooth_coloring;
}

- (void)setSmooth_coloring:(unsigned char)newSmooth
{
	smooth_coloring = newSmooth;
	if (!_disableAutomaticUpdates)
		[self updateCL];
}

- (unsigned char)color_scale
{
	return color_scale;
}

- (void)setColor_scale:(unsigned char)newScale
{
	color_scale = newScale;
	if (!_disableAutomaticUpdates)
		[self updateCL];
}

@end

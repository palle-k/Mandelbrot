//
//  CLMandelbrotView.m
//  Mandelbrot2
//
//  Created by Palle Klewitz on 16.08.14.
//  Copyright (c) 2014 Palle Klewitz. All rights reserved.
//

#import "CLMandelbrotView.h"
#import "kernels.cl.h"

@implementation CLMandelbrotView

#pragma mark - Tiling

/*
 def spiral(X, Y):
     x = y = 0
     dx = 0
     dy = -1
     for i in range(max(X, Y)**2):
         if (-X/2 < x <= X/2) and (-Y/2 < y <= Y/2):
             print (x, y)
             # DO STUFF...
         if x == y or (x < 0 and x == -y) or (x > 0 and x == 1-y):
         dx, dy = -dy, dx
         x, y = x+dx, y+dy
 */


cl_int2 NthTilePosition(unsigned int n, int tilesX, int tilesY)
{
	//NSLog(@"%u. Tile, tilesX: %");
	
	n = tilesX * tilesY - 1 - n;
	
	cl_int2 tilePosition;
	
	int x = 0;
	int y = 0;
	
	int dx = 0;
	int dy = -1;
	
	//int maxSQ = (int)MAX(tilesX, tilesY) * (int)MAX(tilesX, tilesY);
	
	//int tileNum = 0;
	
	for (unsigned int i = 0; i < n;)
	{
		if (-tilesX/2 < x && x <= tilesX/2 && -tilesY/2 < y && y <= tilesY/2)
		{
			i++;
		}
		if (x == y || (x < 0 && x == -y) || (x > 0 && x == 1-y))
		{
			int cache = dx;
			dx = -dy;
			dy = cache;
		}
		if (i < n)
		{
			x += dx;
			y += dy;
		}
	}
	
	//NSLog(@"%i; %i", x, y);
	
	tilePosition.x = MAX(MIN(x + tilesX / 2 - 1, tilesX - 1), 0);
	tilePosition.y = MAX(MIN(y + tilesY / 2 - 1, tilesY - 1), 0);
	
	//NSLog(@"%i; %i", tilePosition.x, tilePosition.y);
	
	//tilePosition.x = n % tilesX;
	//tilePosition.y = n / tilesX;
	return tilePosition;
}

cl_int2 NthTilePositionFromCenter(unsigned int n, int tilesX, int tilesY)
{
	cl_int2 tilePosition;
	
	int x = tilesX / 2;
	int y = tilesY / 2;
	
	int dx = 1;
	int dy = 0;
	
	for (unsigned int i = 0; i < n;)
	{
		if (x >= 0 && x < tilesX && y >= 0 & y < tilesY)
		{
			i++;
		}
		if ((x - tilesX / 2) == (y - tilesY / 2) || (x - tilesX / 2) == -(y - tilesY / 2))
		{
			int cache = dx;
			dx = -dy;
			dy = cache;
		}
		if (y == 0 && x < tilesX / 2)
		{
			x -= 1;
		}
		x+= dx;
		y+= dy;
	}
	
	tilePosition.x = x;
	tilePosition.y = y;
	
	return tilePosition;
}

#pragma mark - Initialization

- (instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self)
	{
		[self initParameters];
		[self initCL];
		[self initMainTexture];
		[self initPreviewTextureWithFactor:16];
		[self update];
		[self.window makeFirstResponder:self];
	}
	return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if (self)
	{
		[self initParameters];
		[self initCL];
		[self initMainTexture];
		[self initPreviewTextureWithFactor:16];
		[self update];
		[self.window makeFirstResponder:self];
	}
	return self;
}

- (void) initParameters
{
	zoom = 1;
	previewZoom = 1;
	shift.x = 0;
	shift.y = 0;
	iterations = 128;
	color_shift = 2;
	color_factor = 1000;
	renderID = 0;
}

- (void) initCL
{
	if(initialized)
		return;
	width = self.frame.size.width * [[NSScreen mainScreen] backingScaleFactor] * 2;
	height = self.frame.size.height * [[NSScreen mainScreen] backingScaleFactor] * 2;
	usePreview = NO;
	
	[self.openGLContext makeCurrentContext];
	gcl_gl_set_sharegroup(CGLGetShareGroup(CGLGetCurrentContext()));
	cl_queue = gcl_create_dispatch_queue(CL_DEVICE_TYPE_GPU, 0);
	cl_block = dispatch_semaphore_create(0);
	
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_TEXTURE_2D);
	glMatrixMode(GL_PROJECTION);
	glViewport(0, 0, self.bounds.size.width * [[NSScreen mainScreen] backingScaleFactor], self.bounds.size.height * [[NSScreen mainScreen] backingScaleFactor]);
	glOrtho(-1.0f, 1.0f, -1.0f, 1.0f, -1.0f, 1.0f);
	
	initialized = YES;
}

#pragma mark - Texture Initialization

- (void) initMainTexture
{
	const float zero = 0;
	float *mainPixels = (float*) malloc(sizeof(float) * 4 * width * height);
	vDSP_vfill(&zero, mainPixels, 1, 4 * width * height);
	glGenTextures(1, &mainTexture);
	glBindTexture(GL_TEXTURE_2D, mainTexture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP_SGIS, GL_TRUE);
	glTexImage2D(GL_TEXTURE_2D, 0, 4, width, height, 0, GL_RGBA, GL_FLOAT, mainPixels);
	glTexParameterf (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameterf (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	mainImage = gcl_gl_create_image_from_texture(GL_TEXTURE_2D, 0, mainTexture);
	free(mainPixels);
	mainTextureAvailable = YES;
	
}

- (void) initPreviewTextureWithFactor: (int) downscaling
{
	downscaling *= [[NSScreen mainScreen] backingScaleFactor];
	previewWidth = width / downscaling;
	previewHeight = height / downscaling;
	const float zero = 0;
	float *previewPixels = (float*) malloc(sizeof(float) * 4 * previewWidth * previewHeight);
	vDSP_vfill(&zero, previewPixels, 1, 4 * previewWidth * previewHeight);
	glGenTextures(1, &previewTexture);
	glBindTexture(GL_TEXTURE_2D, previewTexture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexImage2D(GL_TEXTURE_2D, 0, 4, previewWidth, previewHeight, 0, GL_RGBA, GL_FLOAT, previewPixels);
	previewImage = gcl_gl_create_image_from_texture(GL_TEXTURE_2D, 0, previewTexture);
	free(previewPixels);
	previewTextureAvailable = YES;
}

#pragma mark Teardown

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

- (void) update
{
	updating = YES;
	__block double sizeX = 2.0 / zoom * width / height;
	__block double sizeY = 2.0 / zoom;
	
	if(!mainTextureAvailable)
		usePreview = YES;
	if(usePreview && !previewTextureAvailable)
		return;
	
	if (usePreview)
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
			mandelbrot_kernel(&range, previewImage, sizeX, sizeY, previewWidth, previewHeight, shift.x, shift.y, iterations, color_factor, color_shift);
			dispatch_semaphore_signal(cl_block);
		});
		dispatch_semaphore_wait(cl_block, DISPATCH_TIME_FOREVER);
		[self drawRect:self.frame];
		updating = NO;
	}
	else
	{
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
		^{
			dispatch_async(cl_queue,
			^{
				cl_ndrange range =
				{
					2,
					{0, 0},
					{width, height},
					{0, 0}
				};
				reset_kernel(&range, mainImage);
				dispatch_semaphore_signal(cl_block);
			});
			dispatch_semaphore_wait(cl_block, DISPATCH_TIME_FOREVER);
			
			renderID++;
			int currentRenderID = renderID;
			
			int baseTiles = 8;
			if(iterations >= 8192)
				baseTiles = 32;
			else if(iterations >= 4096)
				baseTiles = 16;
			int tilesX = (int)((double) baseTiles * width / height);
			int tilesY = baseTiles;
			for (short i = tilesY - 1; i >= 0; i--)
			{
				if(usePreview || renderID != currentRenderID)
					break;
				for (unsigned short j = 0; j < tilesX; j++)
				{
					if(usePreview || renderID != currentRenderID)
						break;
					
					cl_int2 tilePosition = NthTilePosition(j + i * tilesX, tilesX, tilesY);
					
					dispatch_async(cl_queue,
					^{
						size_t wgs;
						gcl_get_kernel_block_workgroup_info((__bridge void *)(mandelbrot_kernel), CL_KERNEL_WORK_GROUP_SIZE, sizeof(wgs), &wgs, NULL);
						cl_ndrange range =
						{
							2,
							{width / tilesX * tilePosition.x, height / tilesY * tilePosition.y},
							{width / tilesX, height / tilesY},
							{0, 0}
						};
						mandelbrot_kernel(&range, mainImage, sizeX, sizeY, width, height, shift.x, shift.y, iterations, color_factor, color_shift);
						dispatch_semaphore_signal(cl_block);
					});
					dispatch_semaphore_wait(cl_block, DISPATCH_TIME_FOREVER);
					
					dispatch_sync(dispatch_get_main_queue(),
					^{
						[self drawRect:self.frame];
					});
				}
			}
			updating = NO;
		});
		
	}
}

- (void)drawRect:(NSRect)dirtyRect
{
	[self.openGLContext makeCurrentContext];
	glClear(GL_COLOR_BUFFER_BIT);
	glDisable(GL_DEPTH_TEST);
	if(!initialized)
		return;
	glMatrixMode(GL_MODELVIEW);
	if(usePreview)
	{
		glBindTexture(GL_TEXTURE_2D, previewTexture);
	}
	else
	{
		glBindTexture(GL_TEXTURE_2D, mainTexture);
		glGenerateMipmap(GL_TEXTURE_2D);
	}
	
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
	
	if (usePreview)
	{
		glDisable(GL_TEXTURE_2D);
		glColor4f(1, 1, 1, 1);
		glLineWidth(1 / [[NSScreen mainScreen] backingScaleFactor]);
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
	
	glFlush();
}

#pragma mark - Window Events

- (void)reshape
{
	[super reshape];
	[self teardown];
	lastChangeTime = CACurrentMediaTime();
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
	^{
		usleep(500000);
		if(CACurrentMediaTime() - lastChangeTime >= 0.5)
		{
			dispatch_async(dispatch_get_main_queue(),
			^{
				[self.openGLContext makeCurrentContext];
				[self.openGLContext update];
				[self initCL];
				[self initPreviewTextureWithFactor:16];
				[self initMainTexture];
				glMatrixMode(GL_PROJECTION);
				glViewport(0, 0, self.bounds.size.width * [[NSScreen mainScreen] backingScaleFactor], self.bounds.size.height * [[NSScreen mainScreen] backingScaleFactor]);
				glOrtho(-1, 1, -1, 1, -1, 1);
				usePreview = NO;
				[self update];
			});
		}
	});
}
/*
- (void)mouseDown:(NSEvent *)theEvent
{
	[self.window makeFirstResponder:self];
	mouseDown = YES;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	usePreview = YES;
	shift.x -= theEvent.deltaX / self.bounds.size.height * 2.0 / zoom;
	shift.y += theEvent.deltaY / self.bounds.size.height * 2.0 / zoom;
	lastChangeTime = CACurrentMediaTime();
	if(!updating)
	{
		[self update];
	}
}

- (void)mouseUp:(NSEvent *)theEvent
{
	mouseDown = NO;
	if(!scrolling)
		usePreview = NO;
	[self update];
}
*/
- (void)keyUp:(NSEvent *)theEvent
{
	if (theEvent.keyCode == 30)
		iterations *= 2;
	else if (theEvent.keyCode == 44)
		iterations /= 2;
	else if (theEvent.keyCode == 7)
		color_factor /= 2;
	else if (theEvent.keyCode == 8)
		color_factor *= 2;
	else if (theEvent.keyCode == 9)
		color_shift -= 0.5f;
	else if (theEvent.keyCode == 11)
		color_shift += 0.5f;
	NSLog(@"iterations: %i, color factor: %f", iterations, color_factor);
	if(iterations >= 8192 && width / previewWidth <= 16 * [NSScreen mainScreen].backingScaleFactor)
	{
		glDeleteTextures(1, &previewTexture);
		[self initPreviewTextureWithFactor:20];
	}
	else if (iterations < 8192 && width / previewWidth > 16 * [NSScreen mainScreen].backingScaleFactor)
	{
		glDeleteTextures(1, &previewTexture);
		[self initPreviewTextureWithFactor:16];
	}
	[self update];
}
/*
- (void)scrollWheel:(NSEvent *)theEvent
{
	usePreview = YES;
	scrolling = YES;
	zoom += theEvent.deltaY * zoom * 0.01f;
	lastChangeTime = CACurrentMediaTime();
	if(theEvent.momentumPhase == NSEventPhaseEnded)
	{
		scrolling = NO;
		if(!mouseDown)
			usePreview = NO;
	}
	[self update];
}
*/

#pragma mark - Control methods

- (void)usePreviewMode:(BOOL)enable
{
	usePreview = enable;
	[self update];
}

- (double)zoom
{
	return zoom;
}

- (void)setZoom:(double)newZoom
{
	zoom = newZoom;
	if(!updating)
		[self update];
}

- (void)shiftBy:(CGVector) pixels
{
	shift.x -= pixels.dx / self.bounds.size.height * 2.0 / zoom;
	shift.y -= pixels.dy / self.bounds.size.height * 2.0 / zoom;
	if(!updating)
		[self update];
}

- (unsigned int)iterations
{
	return iterations;
}

- (void)setIterations:(unsigned int)newIterations
{
	iterations = newIterations;
	if(iterations >= 8192 && width / previewWidth <= 16 * [NSScreen mainScreen].backingScaleFactor)
	{
		glDeleteTextures(1, &previewTexture);
		[self initPreviewTextureWithFactor:20];
	}
	else if (iterations < 8192 && width / previewWidth > 16 * [NSScreen mainScreen].backingScaleFactor)
	{
		glDeleteTextures(1, &previewTexture);
		[self initPreviewTextureWithFactor:16];
	}
	[self update];
}

- (double)color_shift
{
	return color_shift;
}

- (void)setColor_shift:(double)new_color_shift
{
	color_shift = new_color_shift;
	[self update];
}

- (double)color_factor
{
	return color_factor;
}

- (void)setColor_factor:(double)new_color_factor
{
	color_factor = new_color_factor;
	[self update];
}

#pragma mark - Snapshotting

- (GLfloat *)getSnapshot:(size_t *)length
{
	[self.openGLContext makeCurrentContext];
	glBindTexture(GL_TEXTURE_2D, mainTexture);
	
	GLint textureWidth, textureHeight;
	*length = textureWidth * textureHeight * 4 * sizeof(GLfloat);
	
	GLfloat *buffer = (GLfloat *) malloc(textureWidth * textureHeight * 4 * sizeof(GLfloat));
	glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_FLOAT, buffer);
	
	return buffer;
}

- (NSBitmapImageRep *)getShnapshot
{
	size_t bitmap_size;
	GLfloat *snapshotData = [self getSnapshot:&bitmap_size];
	
	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:width pixelsHigh:height bitsPerSample:32 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:width * 4 * 4 bitsPerPixel:128];
	
	free(snapshotData);
	
	return bitmap;
}

@end

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

@synthesize progress = _progress;

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
	n = tilesX * tilesY - 1 - n;
	
	cl_int2 tilePosition;
	/*
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
	
	tilePosition.x = MAX(MIN(x + tilesX / 2 - 1, tilesX - 1), 0);
	tilePosition.y = MAX(MIN(y + tilesY / 2 - 1, tilesY - 1), 0);
	*/
	tilePosition.x = n % tilesX;
	tilePosition.y = n / tilesX;
	return tilePosition;
}

cl_int2 NthTilePositionFromCenter(unsigned int n, int tilesX, int tilesY)
{
	cl_int2 tilePosition;
	
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
		
	}
	return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if (self)
	{
		
	}
	return self;
}

- (void) setup
{
	[self initParameters];
	[self initCL];
	[self initMainTexture];
	[self initPreviewTextureWithFactor:16];
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
	
	cl_queue = gcl_create_dispatch_queue(CL_DEVICE_TYPE_GPU, 0);
	cl_block = dispatch_semaphore_create(0);
	
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
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP_SGIS, GL_TRUE);
	glTexImage2D(GL_TEXTURE_2D, 0, 4, width, height, 0, GL_RGBA, GL_FLOAT, NULL);
	glTexParameterf (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameterf (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
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
	glTexImage2D(GL_TEXTURE_2D, 0, 4, previewWidth, previewHeight, 0, GL_RGBA, GL_FLOAT, NULL);
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
	
	dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0),
	^{
		double sizeX = 2.0 / zoom * width / height;
		double sizeY = 2.0 / zoom;
		
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
		dispatch_sync(dispatch_get_main_queue(),
	    ^{
			[self drawRect:self.frame];
	    });
		if (usePreview)
			updating = NO;
		
		if (!usePreview)
		{
			int baseTiles = 5;
			if(iterations >= 32768)
				baseTiles = 60;
			else if(iterations >= 8192)
				baseTiles = 30;
			else if (iterations >= 4096)
				baseTiles = 20;
			else if (iterations >= 256)
				baseTiles = 10;
			
			if (_optimizeSpeed)
			{
				baseTiles = 3;
				if(iterations >= 32768)
					baseTiles = 30;
				else if(iterations >= 8192)
					baseTiles = 20;
				else if (iterations >= 4096)
					baseTiles = 15;
				else if (iterations >= 256)
					baseTiles = 8;
			}
			
			int tilesX = (int)((double) baseTiles * width / height);
			int tilesY = baseTiles;
			
			dispatch_sync(dispatch_get_main_queue(), ^{_progress.totalUnitCount = tilesX * tilesY;_progress.completedUnitCount = 0;});
			
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
			
			mainTextureInvalid = NO;
			renderID++;
			int currentRenderID = renderID;
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
						_progress.completedUnitCount++;
						//NSLog(@"Progress: %@; %@", _progress.localizedDescription, _progress.localizedAdditionalDescription);
						[self drawRect:self.frame];
					});
				}
			}
			dispatch_sync(dispatch_get_main_queue(), ^{_progress.completedUnitCount = _progress.totalUnitCount;});
			if (renderID == currentRenderID)
				updating = NO;
			dispatch_sync(dispatch_get_main_queue(),
			^{
				[self drawRect:self.frame];
			});
			if (renderID == currentRenderID)
				[self.delegate mandelbrotViewDidFinishRendering:self];
		}
	});
}

- (void)drawRect:(NSRect)dirtyRect
{
	[self.openGLContext makeCurrentContext];
	glClear(GL_COLOR_BUFFER_BIT);
	glDisable(GL_DEPTH_TEST);
	if(!initialized)
		return;
	glMatrixMode(GL_MODELVIEW);
	
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
	glGenerateMipmap(GL_TEXTURE_2D);
	
	if (usePreview && !mainTextureInvalid)
	{
		double relativeZoom = zoom / previewZoom;

		if (relativeZoom < 32)
		{
			double relativeShiftX = (shift.x - previewShift.x) * zoom * height / width;
			double relativeShiftY = (shift.y - previewShift.y) * zoom;
			
			glBegin(GL_QUADS);
			{
				glTexCoord2d(0.0f, 0.0f);
				glVertex2f(-1.0f * relativeZoom - relativeShiftX, -1.0f * relativeZoom - relativeShiftY);
				
				glTexCoord2d(1.0f, 0.0f);
				glVertex2f(1.0f * relativeZoom - relativeShiftX, -1.0f * relativeZoom - relativeShiftY);
				
				glTexCoord2d(1.0f, 1.0f);
				glVertex2f(1.0f * relativeZoom - relativeShiftX, 1.0f * relativeZoom - relativeShiftY);
				
				glTexCoord2d(0.0f, 1.0f);
				glVertex2f(-1.0f * relativeZoom - relativeShiftX, 1.0f * relativeZoom - relativeShiftY);
			}
			glEnd();
		}
	}
	else if (!usePreview)
	{
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
	
	glFlush();
}

#pragma mark - Window Events

- (void)reshape
{
	[super reshape];
	
	if (width == self.frame.size.width * devicePixelRatio && height == self.frame.size.height * devicePixelRatio)
		return;
	
	[self teardown];
	devicePixelRatio = [self.window.screen backingScaleFactor];
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
				glViewport(0, 0, self.bounds.size.width * devicePixelRatio, self.bounds.size.height * devicePixelRatio);
				glOrtho(-1, 1, -1, 1, -1, 1);
				usePreview = NO;
				if (!_disableAutomaticUpdates)
					[self updateCL];
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
		[self updateCL];
	}
}

- (void)mouseUp:(NSEvent *)theEvent
{
	mouseDown = NO;
	if(!scrolling)
		usePreview = NO;
	[self updateCL];
}
*/

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
	[self updateCL];
}
*/

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
	if(!updating && _disableAutomaticUpdates)
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
		[self initPreviewTextureWithFactor:24];
	}
	else if (iterations < 8192 && width / previewWidth > 16 * devicePixelRatio)
	{
		glDeleteTextures(1, &previewTexture);
		[self initPreviewTextureWithFactor:16];
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
	NSLog(@"shift: x: %f; y: %f", shift.x, shift.y);
	return shift;
}

- (void)setShift:(cl_double2)newShift
{
	shift = newShift;
	if (!_disableAutomaticUpdates)
		[self updateCL];
}

@end

//
//  CLMandelbrotView.h
//  Mandelbrot2
//
//  Created by Palle Klewitz on 16.08.14.
//  Copyright (c) 2014 Palle Klewitz. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenCL/opencl.h>
#import <OpenCL/cl.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import <Accelerate/Accelerate.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>

@interface CLMandelbrotView : NSOpenGLView
{
	unsigned int width;
	unsigned int height;
	unsigned int previewWidth;
	unsigned int previewHeight;
	
	unsigned int iterations;
	double color_shift;
	double color_factor;
	
	double zoom;
	double previewZoom;
	cl_double2 shift;
	cl_double2 previewShift;
	
	dispatch_queue_t cl_queue;
	dispatch_semaphore_t cl_block;
	
	GLuint mainTexture;
	GLuint previewTexture;
	cl_image mainImage;
	cl_image previewImage;
	
	BOOL usePreview;
	BOOL mouseDown;
	BOOL scrolling;
	BOOL initialized;
	BOOL updating;
	BOOL mainTextureAvailable;
	BOOL previewTextureAvailable;
	
	double lastChangeTime;
	
	int renderID;
}

- (void) usePreviewMode: (BOOL) enable;
- (void) shiftBy: (CGVector) pixels;
- (GLfloat *) getSnapshot:(size_t *) length;
- (NSBitmapImageRep *) getShnapshot;

@property (nonatomic, readwrite) double zoom;
@property (nonatomic, readwrite) unsigned int iterations;
@property (nonatomic, readwrite) double color_shift;
@property (nonatomic, readwrite) double color_factor;

@end

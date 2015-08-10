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
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>

@class CLMandelbrotView;

@protocol CLMandelbrotViewDelegate <NSObject>

- (void) mandelbrotViewDidFinishRendering:(nonnull CLMandelbrotView *) mandelbrotView;

@end

@interface CLMandelbrotView : NSOpenGLView <NSProgressReporting>
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
	
	double devicePixelRatio;
	
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
	BOOL mainTextureInvalid;
	BOOL previewTextureAvailable;
	
	double lastChangeTime;
	
	int renderID;
}

- (void) usePreviewMode: (BOOL) enable;
- (void) shiftBy: (CGVector) pixels;
- (GLubyte * __nullable) getSnapshot:( size_t * _Null_unspecified) length;
- (NSBitmapImageRep * _Nullable) getShnapshot;
- (void) setup;
- (void) updateCL;

@property (nonatomic, readwrite) BOOL disableAutomaticUpdates;
@property (nonatomic, readwrite) BOOL userInteractionDisabled;
@property (nonatomic, readwrite) BOOL optimizeSpeed;

@property (nonatomic, readonly) CGSize textureSize;
@property (nonatomic, readwrite) cl_double2 shift;
@property (nonatomic, readwrite) double zoom;
@property (nonatomic, readwrite) unsigned int iterations;
@property (nonatomic, readwrite) double color_shift;
@property (nonatomic, readwrite) double color_factor;
@property (weak, nonatomic, readwrite, nullable) id<CLMandelbrotViewDelegate> delegate;

@end

//
//  CLMandelbrotView.h
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

@import Cocoa;
@import QuartzCore;
@import CoreGraphics;
#import <OpenCL/opencl.h>
#import <OpenCL/cl.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

@class CLMandelbrotView;

@protocol CLMandelbrotViewDelegate <NSObject>

- (void) mandelbrotViewDidFinishRendering:(nonnull CLMandelbrotView *) mandelbrotView;

@end

@protocol CLMandelbrotViewControlDelegate <NSObject>

- (void) mandelbrotView:(nonnull CLMandelbrotView *) mandelbrotView didUpdateProgress:(nonnull NSProgress *) progress;
- (void) mandelbrotViewDidChangeSetup:(nonnull CLMandelbrotView *) mandelbrotView;

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
	unsigned char color_mode;
	unsigned char color_scale;
	unsigned char smooth_coloring;
	
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
@property (nonatomic, readwrite) unsigned char color_mode;
@property (weak, nonatomic, readwrite, nullable) id<CLMandelbrotViewDelegate> delegate;
@property (weak, nonatomic, readwrite, nullable) id<CLMandelbrotViewControlDelegate> progressDelegate;
@property (nonatomic, readwrite) unsigned char smooth_coloring;
@property (nonatomic, readwrite) unsigned char color_scale;

@end

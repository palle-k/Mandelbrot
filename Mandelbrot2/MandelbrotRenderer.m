//
//  MandelbrotRenderer.m
//  Mandelbrot2
//
//  Created by Palle Klewitz on 06.08.15.
//  Copyright © 2015 - 2016 Palle Klewitz.
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

@import AVFoundation;
#import "MandelbrotRenderer.h"
#import "CLMandelbrotView.h"

double AnimationValue(double start, double end, unsigned int frame, unsigned int totalFrames)
{
	double progress = (double) frame / (double)totalFrames;
	double delta = end - start;
	double result = start + delta * progress;
	return result;
}

@interface MandelbrotRenderer ()

@property (nonatomic, strong) AVAssetWriter *writer;
@property (nonatomic, strong) AVAssetWriterInput *input;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *adaptor;
@property (nonatomic) dispatch_queue_t writer_queue;
@property (nonatomic) dispatch_semaphore_t callback_semaphore;
@property (nonatomic) unsigned int frame;

@end

@interface MandelbrotRenderer ()

@property (nonatomic) CFTimeInterval startDate;

@end

@implementation MandelbrotRenderer
@synthesize progress = _progress;

+ (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image
{
	CGSize frameSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey, [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
	CVPixelBufferRef pxbuffer = NULL;
	
	CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width, frameSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef)options, &pxbuffer);
	assert(status == kCVReturnSuccess && pxbuffer != NULL);
	
	CVPixelBufferLockBaseAddress(pxbuffer, 0);
	void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
	
	CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(pxdata, frameSize.width, frameSize.height, 8, CVPixelBufferGetBytesPerRow(pxbuffer), rgbColorSpace, (CGBitmapInfo)kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
	
	CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
	CGColorSpaceRelease(rgbColorSpace);
	CGContextRelease(context);
	
	CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
	
	return pxbuffer;
}

- (void)startRendering
{
	_progress = [[NSProgress alloc] init];
	_progress.totalUnitCount = _frames_per_second * _video_length;
	_progress.completedUnitCount = -1;
	[_delegate didUpdateProgress];
	_writer_queue = dispatch_queue_create("com.palleklewitz.mandelbrotRendererQueue", DISPATCH_QUEUE_SERIAL);
	_callback_semaphore = dispatch_semaphore_create(0);
	
	NSError *error;
	_writer = [[AVAssetWriter alloc] initWithURL:_targetFile fileType:AVFileTypeQuickTimeMovie error:&error];
	if (!_writer)
	{
		[self.delegate mandelbrotRenderer:self didFailWithError:error];
		return;
	}
	NSDictionary *videoSettings = @{
										AVVideoCodecKey : AVVideoCodecH264,
										AVVideoWidthKey : @(self.mandelbrotView.textureSize.width),
										AVVideoHeightKey : @(self.mandelbrotView.textureSize.height),
										AVVideoCompressionPropertiesKey :
										@{
											AVVideoAverageBitRateKey : @(self.mandelbrotView.textureSize.width * self.mandelbrotView.textureSize.height * _frames_per_second * 2), // 64 000 kbits/s
											AVVideoProfileLevelKey : AVVideoProfileLevelH264HighAutoLevel,
											AVVideoMaxKeyFrameIntervalKey : @(1)
										}
									};
	
	_input = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
	
	_adaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:_input sourcePixelBufferAttributes:nil];
	
	_input.expectsMediaDataInRealTime = NO;
	
	if (!_input)
	{
		[self.delegate mandelbrotRenderer:self didFailWithError:[[NSError alloc] initWithDomain:@"com.palleklewitz.mandelbrot.renderer_input_error" code:1 userInfo:nil]];
		return;
	}
	
	if (![_writer canAddInput:_input])
	{
		[self.delegate mandelbrotRenderer:self didFailWithError:[[NSError alloc] initWithDomain:@"com.palleklewitz.mandelbrot.renderer_input_error" code:2 userInfo:nil]];
		return;
	}
	[_writer addInput:_input];
	[_writer startWriting];
	[_writer startSessionAtSourceTime:CMTimeMake(0, _frames_per_second)];
	_mandelbrotView.optimizeSpeed = YES;
	[self renderLoop];
}

- (void) renderLoop
{
	_frame = 0;
	[_adaptor.assetWriterInput requestMediaDataWhenReadyOnQueue:_writer_queue usingBlock:
	^{
		while (YES)
		{
			_frame++;
			if (_frame >= _frames_per_second * _video_length)
			{
				[self finishRendering];
				return;
			}
			[self applySettings];
			dispatch_semaphore_wait(_callback_semaphore, DISPATCH_TIME_FOREVER);
			__block CVPixelBufferRef pixelBuffer;
			dispatch_sync(dispatch_get_main_queue(),
			^{
				NSBitmapImageRep *rep = [_mandelbrotView getShnapshot];
				pixelBuffer = [MandelbrotRenderer pixelBufferFromCGImage:rep.CGImage];
				
			});
			while (!_adaptor.assetWriterInput.readyForMoreMediaData)
			{
				[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
			}
			[_adaptor appendPixelBuffer:pixelBuffer withPresentationTime:CMTimeMake(_frame, _frames_per_second)];
			dispatch_async(dispatch_get_main_queue(),
			^{
				_progress.totalUnitCount = _frame;
			});
			[_delegate didUpdateProgress];
		}
	}];
}

- (void) applySettings
{
	dispatch_async(dispatch_get_main_queue(),
	^{
		unsigned int totalFrames = (unsigned int)(_frames_per_second * _video_length);
		cl_double2 shift;
		shift.x = AnimationValue(_startX, _endX, _frame, totalFrames);
		shift.y = AnimationValue(_startY, _endY, _frame, totalFrames);
		
		double startZoomLog = log2(_startZoom);
		double endZoomLog = log2(_endZoom);
		
		double startIterationLog = log2(_startIterations);
		double endIterationLog = log2(_endIterations);
		
		_mandelbrotView.shift = shift;
		_mandelbrotView.zoom = pow(2.0, AnimationValue(startZoomLog, endZoomLog, _frame, totalFrames));
		_mandelbrotView.iterations = (unsigned int)pow(2.0, AnimationValue(startIterationLog, endIterationLog, _frame, totalFrames));
		_mandelbrotView.color_shift = AnimationValue(_startColorShift, _endColorShift, _frame, totalFrames);
		_mandelbrotView.color_factor = AnimationValue(_startColorFactor, _endColorFactor, _frame, totalFrames);
		[_mandelbrotView updateCL];
	});
}

- (void)finishRendering
{
	[_delegate didUpdateProgress];
	_progress.totalUnitCount = -1;
	[_input markAsFinished];
	[_writer endSessionAtSourceTime:CMTimeMakeWithSeconds(_video_length * _frames_per_second, _frames_per_second)];
	[_writer finishWritingWithCompletionHandler:
	^{
		[_delegate didFinishRendering];
	}];
	dispatch_async(dispatch_get_main_queue(),
	^{
		_mandelbrotView.optimizeSpeed = NO;
	});
}

- (void)mandelbrotViewDidFinishRendering:(nonnull CLMandelbrotView *)mandelbrotView
{
	dispatch_semaphore_signal(_callback_semaphore);
}

- (void)setMandelbrotView:(CLMandelbrotView *)mandelbrotView
{
	_mandelbrotView = mandelbrotView;
	_mandelbrotView.delegate = self;
}

@end

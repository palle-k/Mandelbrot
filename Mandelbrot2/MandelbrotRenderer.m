//
//  MandelbrotRenderer.m
//  Mandelbrot2
//
//  Created by Palle Klewitz on 06.08.15.
//  Copyright © 2015 Palle Klewitz. All rights reserved.
//

@import AVFoundation;
#import "MandelbrotRenderer.h"
#import "CLMandelbrotView.h"
#import "CVImageUtils.h"

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
									/*AVVideoCompressionPropertiesKey : @{
											AVVideoAverageBitRateKey : @(64*1000*1000), // 64 000 kbits/s
											AVVideoProfileLevelKey : AVVideoProfileLevelH264HighAutoLevel,
											AVVideoMaxKeyFrameIntervalKey : @(1)
											}*/
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
				pixelBuffer = [CVImageUtils pixelBufferFromCGImage:rep.CGImage];
				
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
		
		NSLog(@"startX=%f; endX=%f", _startX, _endX);
		
		_mandelbrotView.shift = shift;
		_mandelbrotView.zoom = AnimationValue(_startZoom, _endZoom, _frame, totalFrames);
		_mandelbrotView.iterations = (unsigned int)AnimationValue(_startIterations, _endIterations, _frame, totalFrames);
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
		NSLog(@"rendering completed");
	}];
	dispatch_async(dispatch_get_main_queue(),
	^{
		_mandelbrotView.optimizeSpeed = NO;
	});
}

- (void)mandelbrotViewDidFinishRendering:(nonnull CLMandelbrotView *)mandelbrotView
{
	//NSLog(@"MandelbrotView did finish rendering");
	dispatch_semaphore_signal(_callback_semaphore);
}

- (void) processFrame:(NSBitmapImageRep *) rep
{
	//NSData *bitmapData = [rep representationUsingType:NSPNGFileType properties:[[NSDictionary alloc] init]];
	//[bitmapData writeToURL:[NSURL URLWithString:@"file:///Users/Palle/Desktop/current.png"] atomically:YES];
	CVPixelBufferRef pixelBuffer = [self pixelBufferFromCGImage:rep.CGImage size:rep.size];
	NSLog(@"%p", pixelBuffer);
	[_adaptor appendPixelBuffer:pixelBuffer withPresentationTime:CMTimeMake(_frame, _frames_per_second)];
	CVPixelBufferRelease(pixelBuffer);
}

- (void)setMandelbrotView:(CLMandelbrotView *)mandelbrotView
{
	_mandelbrotView = mandelbrotView;
	_mandelbrotView.delegate = self;
}

- (CVPixelBufferRef )pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size
{
	CVPixelBufferRef pxbuffer = NULL;
	CVReturn status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, _adaptor.pixelBufferPool, &pxbuffer);
	
	if (status != kCVReturnSuccess || pxbuffer == NULL)
	{
		NSLog(@"buffer not from pool");
		NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey, [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
		CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options, &pxbuffer);
		NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
	}
	
	CVPixelBufferLockBaseAddress(pxbuffer, 0);
	void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
	
	CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(pxdata, size.width, size.height, 8, 4*size.width, rgbColorSpace, 2);
	CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
	CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
	CGColorSpaceRelease(rgbColorSpace);
	CGContextRelease(context);
	
	CVPixelBufferUnlockBaseAddress(pxbuffer, 0);

	return pxbuffer;
}

@end

//
//  CVImageUtils.m
//  Mandelbrot2
//
//  Created by Palle Klewitz on 07.08.15.
//  Copyright © 2015 Palle Klewitz. All rights reserved.
//

#import "CVImageUtils.h"
@import AVFoundation;

@implementation CVImageUtils

+ (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image
{
	CGSize frameSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey, [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
	CVPixelBufferRef pxbuffer = NULL;
	
	CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width, frameSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef)options, &pxbuffer);
	NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
	
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

+ (CMSampleBufferRef)sampleBufferFromCGImage:(CGImageRef)image
{
	CVPixelBufferRef pixelBuffer = [CVImageUtils pixelBufferFromCGImage:image];
	CMSampleBufferRef newSampleBuffer = NULL;
	CMSampleTimingInfo timimgInfo = kCMTimingInfoInvalid;
	CMVideoFormatDescriptionRef videoInfo;
	CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);
	CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, true, NULL, NULL, videoInfo, &timimgInfo, &newSampleBuffer);
	
	return newSampleBuffer;
}
@end
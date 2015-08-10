//
//  CVImageUtils.h
//  Mandelbrot2
//
//  Created by Palle Klewitz on 07.08.15.
//  Copyright © 2015 Palle Klewitz. All rights reserved.
//

@import AVFoundation;
@import Foundation;

@interface CVImageUtils : NSObject

/**
 Constructs a ``CMSampleBufferRef`` from the given ``CGImageRef``
 
 @param image the ``CGImageRef`` to be turned into ``CMSampleBufferRef``
 @return the converted ``CMSampleBufferRef``
 */
+ (CMSampleBufferRef)sampleBufferFromCGImage:(CGImageRef)image;
+ (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image;
@end

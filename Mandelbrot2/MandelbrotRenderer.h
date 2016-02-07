//
//  MandelbrotRenderer.h
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

@import Foundation;
@class CLMandelbrotView;
@class MandelbrotRenderer;
#import "CLMandelbrotView.h"

@protocol MandelbrotRendererDelegate <NSObject>

- (void) mandelbrotRenderer: (nonnull MandelbrotRenderer *) renderer didFailWithError:(nullable NSError *) error;
- (void) didUpdateProgress;
- (void) didFinishRendering;

@end

@interface MandelbrotRenderer : NSObject <CLMandelbrotViewDelegate, NSProgressReporting>

@property (nonatomic, weak, nullable) CLMandelbrotView *mandelbrotView;
@property (nonatomic, weak, nullable) id<MandelbrotRendererDelegate> delegate;

@property (nonatomic) double startX;
@property (nonatomic) double startY;
@property (nonatomic) double startZoom;
@property (nonatomic) unsigned int startIterations;
@property (nonatomic) double startColorFactor;
@property (nonatomic) double startColorShift;

@property (nonatomic) double endX;
@property (nonatomic) double endY;
@property (nonatomic) double endZoom;
@property (nonatomic) unsigned int endIterations;
@property (nonatomic) double endColorFactor;
@property (nonatomic) double endColorShift;

@property (nonatomic, strong, nullable) NSURL *targetFile;

@property (nonatomic) double frames_per_second;
@property (nonatomic) NSTimeInterval video_length;
@property (nonatomic, readonly) unsigned int frame;

- (void) startRendering;

@end
